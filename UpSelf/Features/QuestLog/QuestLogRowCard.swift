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
            // MARK: Leading — title + meta
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(quest.title)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(done ? 0.45 : 0.92))
                    .strikethrough(done, color: .white.opacity(0.3))
                    .lineLimit(3)

                HStack(spacing: AppTheme.Spacing.sm) {
                    if let kind = quest.statKind {
                        statChip(for: kind)
                    }

                    if let target = quest.weeklyTarget, quest.isCommitted {
                        weeklyTargetChip(target: target)
                    }
                }

                if tierBlockedInLockdown {
                    Text(L10n.Lockdown.questRowLockedLabel)
                        .font(AppTheme.Fonts.mono(.caption2))
                        .foregroundStyle(AppTheme.Colors.alertHP.opacity(0.95))
                }
            }

            Spacer(minLength: AppTheme.Spacing.sm)

            // MARK: Trailing — XP + status
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                if let tier = quest.rewardTier {
                    xpChip(xp: tier.xp)
                }

                if tierBlockedInLockdown {
                    Image(systemName: "lock.fill")
                        .font(AppTheme.Fonts.ui(.caption))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                } else if !canComplete, done {
                    Text(quest.isGoal ? L10n.HUD.questDoneOnce : L10n.HUD.questDoneToday)
                        .font(AppTheme.Fonts.mono(.caption2))
                        .foregroundStyle(AppTheme.Colors.accentXP.opacity(0.7))
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
        .opacity(tierBlockedInLockdown ? 0.85 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel())
        .accessibilityHint(canComplete ? L10n.Accessibility.questSwipeHint : "")
    }

    // MARK: - Sub-views

    private func statChip(for kind: CharacterAttribute) -> some View {
        HStack(spacing: 4) {
            AppTheme.Icons.icon(for: kind).view(size: 11, color: AppTheme.Colors.secondaryLabel)
            Text(L10n.Stats.title(for: kind))
                .font(AppTheme.Fonts.mono(.caption))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)
        }
    }

    private func weeklyTargetChip(target: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "repeat")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AppTheme.Colors.secondaryLabel.opacity(0.7))
            Text("\(target)×/wk")
                .font(AppTheme.Fonts.mono(.caption2))
                .foregroundStyle(AppTheme.Colors.secondaryLabel.opacity(0.7))
        }
    }

    private func xpChip(xp: Int) -> some View {
        Text(L10n.HUD.xpFormat(xp: xp))
            .font(AppTheme.Fonts.mono(.caption))
            .foregroundStyle(done ? AppTheme.Colors.accentXP.opacity(0.45) : AppTheme.Colors.accentXP)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                AppTheme.Colors.accentXP.opacity(done ? 0.06 : 0.12),
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.chip)
            )
    }
}
