//
//  QuestCompletionService.swift
//  UpSelf
//
//  Encapsulates the full quest-completion transaction: eligibility, XP grant,
//  activity log, lockdown counters, save, and rollback on failure.
//

import Foundation
import SwiftData

enum QuestCompletionResult {
    case completed
    case completedAndClearedLockdown
    /// The quest's tier is blocked while in lockdown (easy/regular). Caller should present an alert.
    case tierBlockedInLockdown
    /// Quest is not eligible to be completed right now (already done, missing profile/stat).
    case notEligible
}

protocol QuestCompletionServiceProtocol: AnyObject {
    @MainActor
    func complete(_ quest: Quest, context: ModelContext) throws -> QuestCompletionResult
}

final class QuestCompletionService: QuestCompletionServiceProtocol {

    private let gameClock: GameClock
    private let activityLogService: ActivityLogServiceProtocol

    init(
        gameClock: GameClock,
        activityLogService: ActivityLogServiceProtocol = DependencyContainer[\.activityLogService]
    ) {
        self.gameClock = gameClock
        self.activityLogService = activityLogService
    }

    @MainActor
    func complete(_ quest: Quest, context: ModelContext) throws -> QuestCompletionResult {
        let ref = gameClock.now
        let calendar = Calendar.current

        // 1. Eligibility check — recovery path for hard/epic in lockdown
        let canProceed: Bool = {
            guard let profile = quest.user, profile.isInLockdown else {
                return quest.canComplete(referenceDate: ref)
            }
            guard let tier = QuestRewardTier(xp: quest.rewardXP), tier == .hard || tier == .epic else {
                return quest.canComplete(referenceDate: ref)
            }
            return quest.recoveryListCanComplete(
                referenceDate: ref,
                lockdownEpisodeStart: profile.lockdownEpisodeStart
            )
        }()
        guard canProceed else { return .notEligible }

        guard let attribute = quest.statKind,
              let profile = quest.user,
              let stat = profile.stats.first(where: { $0.kindRawValue == attribute.rawValue })
        else { return .notEligible }

        let tier = QuestRewardTier(xp: quest.rewardXP) ?? .easy

        // 2. Lockdown tier gate — easy/regular blocked while in lockdown
        if profile.isInLockdown, !LockdownPolicy.allows(.completeQuest(tier: tier), isInLockdown: true) {
            return .tierBlockedInLockdown
        }

        // 3. Snapshot for rollback
        let previousCompleted = quest.lastCompleted
        let previousXP = stat.currentXP
        let previousEpic = profile.lockdownEpicCompletions
        let previousHard = profile.lockdownHardCompletions
        let previousInLockdown = profile.isInLockdown
        let previousEpisodeStart = profile.lockdownEpisodeStart
        let previousHP = profile.currentHP
        let previousWeeklyCount = quest.weeklyCompletionCount
        let previousWeeklyWeekOf = quest.weeklyCompletionWeekOf

        // 4. Apply changes
        stat.currentXP += tier.xp
        guard let insertedLog = activityLogService.insertQuestXPGain(
            context: context,
            stat: stat,
            tier: tier,
            questTitle: quest.title
        ) else {
            stat.currentXP = previousXP
            return .notEligible
        }
        quest.lastCompleted = ref

        // Update weekly completion counter for committed quests
        if quest.weeklyTarget != nil {
            let weekStart = calendar.mondayStart(for: ref)
            if let existingWeekOf = quest.weeklyCompletionWeekOf,
               calendar.isDate(existingWeekOf, inSameDayAs: weekStart) {
                quest.weeklyCompletionCount += 1
            } else {
                quest.weeklyCompletionCount = 1
                quest.weeklyCompletionWeekOf = weekStart
            }
        }

        var clearedLockdown = false
        if profile.isInLockdown {
            LockdownPolicy.repairInvalidRecoveryMinimums(profile)
            switch tier {
            case .hard:  profile.lockdownHardCompletions += 1
            case .epic:  profile.lockdownEpicCompletions += 1
            case .easy, .regular: break
            }
            if LockdownPolicy.shouldClearLockdown(
                epicCompletions: profile.lockdownEpicCompletions,
                hardCompletions: profile.lockdownHardCompletions,
                minEpicToClear: profile.lockdownMinEpicQuestsToClear,
                minHardToClear: profile.lockdownMinHardQuestsToClear
            ) {
                profile.isInLockdown = false
                profile.lockdownEpicCompletions = 0
                profile.lockdownHardCompletions = 0
                profile.lockdownEpisodeStart = nil
                profile.currentHP = profile.maxHP
                clearedLockdown = true
            }
        }

        // 5. Persist — rollback on failure
        do {
            try context.save()
        } catch {
            context.delete(insertedLog)
            stat.currentXP = previousXP
            quest.lastCompleted = previousCompleted
            quest.weeklyCompletionCount = previousWeeklyCount
            quest.weeklyCompletionWeekOf = previousWeeklyWeekOf
            profile.lockdownEpicCompletions = previousEpic
            profile.lockdownHardCompletions = previousHard
            profile.isInLockdown = previousInLockdown
            profile.lockdownEpisodeStart = previousEpisodeStart
            profile.currentHP = previousHP
            throw error
        }

        return clearedLockdown ? .completedAndClearedLockdown : .completed
    }
}
