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
        dailyQuests.filter { $0.displayAsCompleted() }.count
    }

    private var hasOneOffQuestsOnly: Bool {
        dailyQuests.isEmpty && quests.contains { !$0.isDaily }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                header
                hpSection
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
            .accessibilityLabel(L10n.HUD.addQuest)
        }
    }

    private var questLogEntryCard: some View {
        Button {
            viewModel.presentQuestLog()
        } label: {
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
                }
                Spacer(minLength: AppTheme.Spacing.sm)
                Image(systemName: "chevron.right")
                    .font(AppTheme.Fonts.ui(.body))
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(AppTheme.Colors.card.opacity(0.92))
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(AppTheme.Colors.cardStroke, lineWidth: AppTheme.Stroke.cardLine)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.HUD.openQuestLog)
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

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.bar)
                    .fill(AppTheme.Colors.card)
                RoundedRectangle(cornerRadius: AppTheme.Radius.bar)
                    .fill(LinearGradient(
                        colors: [AppTheme.Colors.accentXP, hpFillEnd(ratio: ratio)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(width, ratio > 0 ? 4 : 0))
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
            Text(L10n.HUD.attributesTitle)
                .font(AppTheme.Fonts.ui(.headline))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)

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
