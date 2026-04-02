//
//  DashboardView.swift
//  UpSelf
//
//  Main HUD: HP bar and six stat cards (SwiftData via @Query).
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \CharacterStat.kindRawValue) private var allStats: [CharacterStat]

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                header
                hpSection
                statsSection

                Button {
                    viewModel.completeQuest()
                } label: {
                    Text(L10n.HUD.completeQuest)
                        .font(AppTheme.Fonts.ui(.footnote))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.Colors.accentXP.opacity(0.85))
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }

    private var header: some View {
        Text(L10n.App.title)
            .font(AppTheme.Fonts.ui(.largeTitle))
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.Colors.secondaryLabel)
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
        let progress = xpBarFraction(for: stat)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.bar / 2)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: AppTheme.Radius.bar / 2)
                    .fill(AppTheme.Colors.accentXP.opacity(0.9))
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: AppTheme.Bar.xpHeight)
        .accessibilityLabel(L10n.Accessibility.xpProgress)
        .accessibilityValue(L10n.Accessibility.xpPercent(Int(progress * 100)))
    }

    /// Maps current XP into 0...1 for the bar (aligned with `CharacterStat.level` curve).
    private func xpBarFraction(for stat: CharacterStat) -> CGFloat {
        let base = 50.0
        let m = 1.05
        let xp = Double(stat.currentXP)
        let lvl = stat.level
        if lvl <= 1, stat.currentXP <= 0 { return 0 }
        let lower = lvl > 1 ? base * pow(m, Double(lvl - 1)) : 0
        let upper = base * pow(m, Double(lvl))
        let span = upper - lower
        guard span > 0 else { return 0 }
        return CGFloat(min(1, max(0, (xp - lower) / span)))
    }
}

#Preview("Dashboard") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([UserProfile.self, CharacterStat.self, Quest.self])
    let container = try! ModelContainer(for: schema, configurations: config)
    let ctx = ModelContext(container)
    DataSeedService().seedIfNeeded(context: ctx)

    return DashboardView(viewModel: DashboardViewModel())
        .modelContainer(container)
}
