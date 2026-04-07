//
//  QuestLogRowCard.swift
//  UpSelf
//
//  Shared quest row chrome for Quest Log and lockdown recovery list.
//

import SwiftUI

struct QuestLogRowCard: View {
    let quest: Quest
    let done: Bool
    let canComplete: Bool
    let tierBlockedInLockdown: Bool

    private func buildAccessibilityLabel() -> String {
        let xp = quest.rewardTier?.xp ?? 0
        var base = L10n.Accessibility.questRowLabel(title: quest.title, xp: xp)
        if done { base += ", " + L10n.Accessibility.questDone }
        if tierBlockedInLockdown { base += ", " + L10n.Accessibility.questTierBlocked }
        return base
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(quest.title)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .lineLimit(3)
                if let kind = quest.statKind {
                    Text(L10n.Stats.title(for: kind))
                        .font(AppTheme.Fonts.mono(.caption))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }
                if tierBlockedInLockdown {
                    Text(L10n.Lockdown.questRowLockedLabel)
                        .font(AppTheme.Fonts.mono(.caption2))
                        .foregroundStyle(AppTheme.Colors.alertHP.opacity(0.95))
                }
            }
            Spacer(minLength: AppTheme.Spacing.sm)

            VStack(alignment: .trailing, spacing: AppTheme.Spacing.sm) {
                if let tier = quest.rewardTier {
                    Text(L10n.HUD.xpFormat(xp: tier.xp))
                        .font(AppTheme.Fonts.mono(.subheadline))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }

                if tierBlockedInLockdown {
                    Image(systemName: "lock.fill")
                        .font(AppTheme.Fonts.ui(.caption))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }

                if !canComplete, done {
                    Text(quest.isDaily ? L10n.HUD.questDoneToday : L10n.HUD.questDoneOnce)
                        .font(AppTheme.Fonts.mono(.caption2))
                        .foregroundStyle(AppTheme.Colors.accentXP.opacity(0.9))
                        .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
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
                .stroke(
                    tierBlockedInLockdown ? AppTheme.Colors.alertHP.opacity(0.35) : AppTheme.Colors.cardStroke,
                    lineWidth: AppTheme.Stroke.cardLine
                )
        )
        .shadow(
            color: .black.opacity(0.35),
            radius: AppTheme.Shadow.cardRadius,
            x: 0,
            y: AppTheme.Shadow.cardY
        )
        .opacity(done ? 0.6 : (tierBlockedInLockdown ? 0.85 : 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel())
        .accessibilityHint(canComplete ? L10n.Accessibility.questSwipeHint : "")
    }
}
