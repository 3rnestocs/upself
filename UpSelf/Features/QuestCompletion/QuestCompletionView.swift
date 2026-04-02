//
//  QuestCompletionView.swift
//  UpSelf
//
//  Half-sheet: pick which attribute earned XP for the completed quest.
//

import SwiftData
import SwiftUI
import UIKit

struct QuestCompletionView: View {
    private let stats: [CharacterStat]
    private let viewModel: DashboardViewModel

    init(stats: [CharacterStat], viewModel: DashboardViewModel) {
        self.stats = stats
        self.viewModel = viewModel
    }

    /// Matches the vertical layout + 24pt top/bottom margin for `UISheetPresentationController` custom detents.
    static func preferredSheetDetentHeight(statCount: Int) -> CGFloat {
        let verticalMargin = AppTheme.Spacing.lg * 2
        let titleHeight = UIFont.preferredFont(forTextStyle: .headline).lineHeight
        let titleToGrid = AppTheme.Spacing.lg
        let subheadLine = ceil(UIFont.preferredFont(forTextStyle: .subheadline).lineHeight)
        let buttonPadding = AppTheme.Spacing.md * 2
        let rowHeight = buttonPadding + subheadLine
        let rows = CGFloat(max(1, (statCount + 1) / 2))
        let rowGaps = max(0, rows - 1) * AppTheme.Spacing.md
        let gridHeight = rows * rowHeight + rowGaps
        return verticalMargin + titleHeight + titleToGrid + gridHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text(L10n.HUD.questCompletionTitle)
                .font(AppTheme.Fonts.ui(.headline))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                    GridItem(.flexible(), spacing: AppTheme.Spacing.md)
                ],
                spacing: AppTheme.Spacing.md
            ) {
                ForEach(stats, id: \.id) { stat in
                    attributeButton(stat)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }

    private func attributeButton(_ stat: CharacterStat) -> some View {
        Button {
            viewModel.addXP(to: stat, tier: .easy)
        } label: {
            Group {
                if let kind = stat.kind {
                    Text(L10n.Stats.title(for: kind))
                } else {
                    Text(L10n.Stats.unknown)
                }
            }
            .font(AppTheme.Fonts.ui(.subheadline))
            .fontWeight(.medium)
            .foregroundStyle(Color.white.opacity(0.92))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(AppTheme.Colors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(AppTheme.Colors.cardStroke, lineWidth: AppTheme.Stroke.cardLine)
            )
        }
        .buttonStyle(.plain)
    }
}
