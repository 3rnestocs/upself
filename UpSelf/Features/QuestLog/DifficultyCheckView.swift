//
//  DifficultyCheckView.swift
//  UpSelf
//
//  Sheet shown after the user's 3rd quest completion. Lets the user signal whether
//  the default difficulty is too easy, right, or too hard, then adjusts quest tiers
//  or weekly targets accordingly.
//

import SwiftData
import SwiftUI

struct DifficultyCheckView: View {

    let modelContext: ModelContext
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.sm) {
                AppTheme.Icons.onboardingDifficulty.view(size: 48)

                Text(L10n.Onboarding.difficultyTitle)
                    .font(AppTheme.Fonts.ui(.title3))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(L10n.Onboarding.difficultyBody)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppTheme.Spacing.xl)

            VStack(spacing: AppTheme.Spacing.sm) {
                difficultyButton(
                    label: String(localized: L10n.Onboarding.difficultyTooEasy),
                    icon: "hare.fill",
                    action: { adjust(.tooEasy) }
                )
                difficultyButton(
                    label: String(localized: L10n.Onboarding.difficultyJustRight),
                    icon: "checkmark.circle.fill",
                    action: { adjust(.justRight) }
                )
                difficultyButton(
                    label: String(localized: L10n.Onboarding.difficultyTooHard),
                    icon: "tortoise.fill",
                    action: { adjust(.tooHard) }
                )
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Private

    private func difficultyButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 28)
                Text(label)
                    .font(AppTheme.Fonts.ui(.callout))
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .foregroundStyle(.primary)
            .padding(AppTheme.Spacing.md)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private func adjust(_ feedback: DifficultyFeedback) {
        switch feedback {
        case .tooEasy:
            upgradeTierForEasyQuests()
        case .tooHard:
            reduceWeeklyTargets()
        case .justRight:
            break
        }
        onDismiss()
    }

    /// Raises all easy-tier quests to regular tier.
    private func upgradeTierForEasyQuests() {
        guard let quests = try? modelContext.fetch(FetchDescriptor<Quest>()) else { return }
        for quest in quests where quest.rewardXP == QuestRewardTier.easy.xp {
            quest.rewardXP = QuestRewardTier.regular.xp
        }
        try? modelContext.save()
    }

    /// Reduces the weekly target of all committed quests by 2 days (minimum 1).
    private func reduceWeeklyTargets() {
        guard let quests = try? modelContext.fetch(FetchDescriptor<Quest>()) else { return }
        for quest in quests where quest.weeklyTarget != nil {
            quest.weeklyTarget = max(1, (quest.weeklyTarget ?? 1) - 2)
        }
        try? modelContext.save()
    }
}

private enum DifficultyFeedback {
    case tooEasy, justRight, tooHard
}
