//
//  DashboardView.swift
//  UpSelf
//
//  Main HUD: HP bar, six stat cards, and quest log entry (SwiftData via @Query).
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \CharacterStat.kindRawValue) private var allStats: [CharacterStat]
    @Query(sort: \Quest.title) private var allQuests: [Quest]

    @Bindable private var gameClock = DependencyContainer[\.gameClock]
    @State private var showStatsInfo = false
    @State private var showLockdownRecoveryInfo = false

    private let viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var profile: UserProfile? { profiles.first }

    private var stats: [CharacterStat] {
        guard let id = profile?.id else { return [] }
        let filtered = allStats.filter { $0.user?.id == id }
        return filtered.sorted { a, b in
            let ia = CharacterAttribute.allCases.firstIndex { $0.rawValue == a.kindRawValue } ?? Int.max
            let ib = CharacterAttribute.allCases.firstIndex { $0.rawValue == b.kindRawValue } ?? Int.max
            return ia < ib
        }
    }

    private var quests: [Quest] {
        guard let id = profile?.id else { return [] }
        return allQuests.filter { $0.user?.id == id }
    }

    private var dailyQuests: [Quest] {
        quests
            .filter(\.isDaily)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var completedDailiesToday: Int {
        let ref = gameClock.now
        return dailyQuests.filter { $0.displayAsCompleted(referenceDate: ref) }.count
    }

    private var hasOneOffQuestsOnly: Bool {
        dailyQuests.isEmpty && quests.contains { !$0.isDaily }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                header
                hpSection
                if profile?.isInLockdown == true {
                    recoveryLockdownBanner
                }
                statsSection
                if !quests.isEmpty {
                    questLogEntryCard
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity)
            // ScrollView proposes infinite height; without this, content stretches and stays scrollable
            // even when shorter than the screen (wasted bounce / empty scroll at the bottom).
            .fixedSize(horizontal: false, vertical: true)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .sheet(isPresented: $showStatsInfo) {
            StatsInfoSheet()
        }
        .alert(String(localized: L10n.Lockdown.recoveryInfoAlertTitle), isPresented: $showLockdownRecoveryInfo) {
            Button(String(localized: L10n.Common.ok), role: .cancel) {}
        } message: {
            Text(verbatim: L10n.Lockdown.recoveryInfoAlertMessage(
                minHard: profile?.lockdownMinHardQuestsToClear ?? 0,
                minEpic: profile?.lockdownMinEpicQuestsToClear ?? 0
            ))
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(L10n.App.title)
                .font(AppTheme.Fonts.ui(.largeTitle))
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.secondaryLabel)
            Spacer(minLength: AppTheme.Spacing.sm)
            Button {
                viewModel.presentHistoryLog()
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Colors.accentXP)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.HUD.openActivityLog)
            Button {
                viewModel.presentCreateQuest()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(AppTheme.Colors.accentXP, AppTheme.Colors.card)
            }
            .buttonStyle(.plain)
            .disabled(!createQuestAllowed)
            .opacity(createQuestAllowed ? 1 : 0.35)
            .accessibilityLabel(L10n.HUD.addQuest)
        }
    }

    private var createQuestAllowed: Bool {
        guard let profile else { return true }
        return LockdownPolicy.allows(.createQuest, isInLockdown: profile.isInLockdown)
    }

    private var dailyBriefNavAllowed: Bool {
        guard let profile else { return true }
        return LockdownPolicy.allows(.dailyBrief, isInLockdown: profile.isInLockdown)
    }

    private var questLogEntryCard: some View {
        Group {
            if dailyBriefNavAllowed {
                Button {
                    viewModel.presentQuestLog()
                } label: {
                    questLogEntryCardContent(showChevron: true)
                }
                .buttonStyle(.plain)
            } else {
                questLogEntryCardContent(showChevron: false)
                    .opacity(0.85)
            }
        }
        .accessibilityLabel(L10n.HUD.openQuestLog)
    }

    private func questLogEntryCardContent(showChevron: Bool) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                if hasOneOffQuestsOnly {
                    Text(L10n.QuestLog.title)
                        .font(AppTheme.Fonts.ui(.headline))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    Text(L10n.QuestLog.dashboardOneOffTeaser)
                        .font(AppTheme.Fonts.mono(.subheadline))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                } else {
                    Text(L10n.HUD.dailyBriefingTitle)
                        .font(AppTheme.Fonts.ui(.headline))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    Text(L10n.HUD.dailyBriefingSummary(completed: completedDailiesToday, total: dailyQuests.count))
                        .font(AppTheme.Fonts.mono(.subheadline))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
                if !dailyBriefNavAllowed {
                    Text(L10n.Lockdown.dailyBriefBlockedFootnote)
                        .font(AppTheme.Fonts.mono(.caption))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                        .padding(.top, AppTheme.Spacing.xs)
                }
            }
            Spacer(minLength: AppTheme.Spacing.sm)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(AppTheme.Fonts.ui(.body))
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.Colors.card)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(AppTheme.Colors.cardStroke, lineWidth: AppTheme.Stroke.cardLine)
        )
    }

    private var recoveryLockdownBanner: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.Lockdown.recoveryTitle)
                    .font(AppTheme.Fonts.ui(.headline))
                    .foregroundStyle(AppTheme.Colors.accentXP)
                Spacer(minLength: AppTheme.Spacing.sm)
                Button {
                    showLockdownRecoveryInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(AppTheme.Fonts.ui(.headline))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Lockdown.recoveryInfoButtonAccessibility)
            }
            Text(L10n.Lockdown.recoveryProgressLine)
                .font(AppTheme.Fonts.mono(.subheadline))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)
            Button {
                viewModel.pushRecoveryQuestList()
            } label: {
                Text(L10n.Lockdown.recoveryViewQuestsButton)
                    .font(AppTheme.Fonts.ui(.body))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Colors.accentXP)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.Colors.card)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(AppTheme.Colors.accentXP.opacity(0.45), lineWidth: AppTheme.Stroke.cardLine * 2)
        )
    }

    private var hpSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(L10n.HUD.hpLabel)
                    .font(AppTheme.Fonts.ui(.headline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                Spacer()
                if let profile {
                    Text(L10n.HUD.hpPair(current: profile.currentHP, max: profile.maxHP))
                        .font(AppTheme.Fonts.mono(.title3))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                } else {
                    Text(L10n.Common.placeholder)
                        .font(AppTheme.Fonts.mono(.title3))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }
            }
            hpBar
        }
    }

    private var hpBar: some View {
        GeometryReader { geo in
            let maxHP = max(profile?.maxHP ?? 1, 1)
            let current = profile?.currentHP ?? 0
            let ratio = min(1, max(0, CGFloat(current) / CGFloat(maxHP)))
            let width = geo.size.width * ratio
            let shouldHeartbeat = Double(ratio) < LockdownPolicy.heartbeatHPRatio

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.bar)
                    .fill(AppTheme.Colors.card)
                Group {
                    if shouldHeartbeat {
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !shouldHeartbeat)) { timeline in
                            let t = timeline.date.timeIntervalSince1970
                            let wave = (sin(t * 2 * .pi / AppTheme.HPHeartbeat.pulseDuration) + 1) / 2
                            let o = AppTheme.HPHeartbeat.fillMinOpacity
                                + (AppTheme.HPHeartbeat.fillMaxOpacity - AppTheme.HPHeartbeat.fillMinOpacity) * CGFloat(wave)
                            RoundedRectangle(cornerRadius: AppTheme.Radius.bar)
                                .fill(LinearGradient(
                                    colors: [AppTheme.Colors.accentXP, hpFillEnd(ratio: ratio)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: max(width, ratio > 0 ? 4 : 0))
                                .opacity(o)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.bar)
                            .fill(LinearGradient(
                                colors: [AppTheme.Colors.accentXP, hpFillEnd(ratio: ratio)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(width, ratio > 0 ? 4 : 0))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: ratio)
            }
        }
        .frame(height: AppTheme.Bar.hpHeight)
    }

    private func hpFillEnd(ratio: CGFloat) -> Color {
        if ratio < 0.35 {
            return AppTheme.Colors.alertHP
        }
        if ratio < 0.6 {
            return AppTheme.Colors.accentXP.opacity(0.85)
        }
        return AppTheme.Colors.accentXP
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.HUD.attributesTitle)
                    .font(AppTheme.Fonts.ui(.headline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                Spacer(minLength: AppTheme.Spacing.sm)
                Button {
                    showStatsInfo = true
                } label: {
                    Image(systemName: "exclamationmark.circle")
                        .font(AppTheme.Fonts.ui(.headline))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.HUD.statsInfoButtonAccessibility)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                    GridItem(.flexible(), spacing: AppTheme.Spacing.md)
                ],
                spacing: AppTheme.Spacing.md
            ) {
                ForEach(stats, id: \.id) { stat in
                    statCard(stat)
                }
            }
        }
    }

    private func statCard(_ stat: CharacterStat) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if let kind = stat.kind {
                Text(L10n.Stats.title(for: kind))
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            } else {
                Text(L10n.Stats.unknown)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            HStack {
                Text(L10n.HUD.levelFormat(level: stat.level))
                    .font(AppTheme.Fonts.mono(.caption))
                    .foregroundStyle(AppTheme.Colors.accentXP)
                Spacer()
                Text(L10n.HUD.xpFormat(xp: stat.currentXP))
                    .font(AppTheme.Fonts.mono(.caption))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
            }

            xpProgressBar(stat: stat)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .fill(AppTheme.Colors.card.opacity(0.92))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(AppTheme.Colors.cardStroke, lineWidth: AppTheme.Stroke.cardLine)
        )
        .shadow(
            color: .black.opacity(0.35),
            radius: AppTheme.Shadow.cardRadius,
            x: 0,
            y: AppTheme.Shadow.cardY
        )
    }

    private func xpProgressBar(stat: CharacterStat) -> some View {
        let progress = stat.xpProgressFraction
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.bar / 2)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: AppTheme.Radius.bar / 2)
                    .fill(AppTheme.Colors.accentXP.opacity(0.9))
                    .frame(width: geo.size.width * progress)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: stat.currentXP)
        .frame(height: AppTheme.Bar.xpHeight)
        .accessibilityLabel(L10n.Accessibility.xpProgress)
        .accessibilityValue(L10n.Accessibility.xpPercent(Int(progress * 100)))
    }
}

// MARK: - Stats info sheet

private struct StatsInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    ForEach(CharacterAttribute.allCases, id: \.self) { attribute in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(L10n.Stats.title(for: attribute))
                                .font(AppTheme.Fonts.ui(.headline))
                                .foregroundStyle(AppTheme.Colors.accentXP)
                            Text(L10n.Stats.description(for: attribute))
                                .font(AppTheme.Fonts.ui(.body))
                                .foregroundStyle(AppTheme.Colors.secondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentSizedSheetMeasureHeight()
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(L10n.HUD.statsInfoTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(L10n.HUD.statsInfoDone)
                    }
                    .tint(AppTheme.Colors.accentXP)
                }
            }
        }
        .contentSizedSheetPresentation()
    }
}
