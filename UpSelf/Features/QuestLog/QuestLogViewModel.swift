//
//  QuestLogViewModel.swift
//  UpSelf
//
//  Quest list and completion; navigation stays in AppCoordinator.
//

import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class QuestLogViewModel {

    private let modelContext: ModelContext
    private let gameClock: GameClock

    /// Shown when the user tries to complete a tier blocked in lockdown (e.g. recovery flow edge cases).
    var lockdownBlockedNotice: String?

    /// Set only for `QuestLogView`: pop the nav stack when lockdown engages (that screen must not stay visible).
    var onLockdownEngagedExit: (() -> Void)?

    /// Set only for `RecoveryQuestListView`: pop and show exit success when lockdown clears from a recovery completion.
    var onLockdownClearedExit: (() -> Void)?

    init(modelContext: ModelContext, gameClock: GameClock) {
        self.modelContext = modelContext
        self.gameClock = gameClock
    }

    func clearLockdownNotice() {
        lockdownBlockedNotice = nil
    }

    /// Awards XP for this quest’s tier, logs activity, sets `lastCompleted` (per calendar day for dailies).
    func completePersistedQuest(_ quest: Quest) {
        let ref = gameClock.now
        let canProceed: Bool = {
            guard let profile = quest.user, profile.isInLockdown else {
                return quest.canComplete(referenceDate: ref)
            }
            guard let tier = QuestRewardTier(xp: quest.rewardXP), tier == .hard || tier == .epic else {
                return quest.canComplete(referenceDate: ref)
            }
            return quest.recoveryListCanComplete(referenceDate: ref, lockdownEpisodeStart: profile.lockdownEpisodeStart)
        }()
        guard canProceed else { return }
        guard let attribute = quest.statKind,
              let profile = quest.user,
              let stat = profile.stats.first(where: { $0.kindRawValue == attribute.rawValue })
        else { return }

        let tier = QuestRewardTier(xp: quest.rewardXP) ?? .easy

        if profile.isInLockdown {
            if !LockdownPolicy.allows(.completeQuest(tier: tier), isInLockdown: true) {
                lockdownBlockedNotice = String(localized: L10n.Lockdown.cannotCompleteEasyRegularBody)
                return
            }
        }

        let delta = tier.xp
        let previousCompleted = quest.lastCompleted
        let previousEpic = profile.lockdownEpicCompletions
        let previousHard = profile.lockdownHardCompletions
        let previousInLockdown = profile.isInLockdown
        let previousLockdownEpisodeStart = profile.lockdownEpisodeStart
        let previousHP = profile.currentHP
        var clearedLockdownThisTransaction = false

        stat.currentXP += delta
        guard let insertedActivityLog = ActivityLogService.insertQuestXPGain(
            context: modelContext,
            stat: stat,
            tier: tier,
            questTitle: quest.title
        ) else {
            stat.currentXP -= delta
            return
        }
        quest.lastCompleted = ref

        if profile.isInLockdown {
            LockdownPolicy.repairInvalidRecoveryMinimums(profile)

            switch tier {
            case .hard:
                profile.lockdownHardCompletions += 1
            case .epic:
                profile.lockdownEpicCompletions += 1
            case .easy, .regular:
                break
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
                clearedLockdownThisTransaction = true
            }
        }

        do {
            try modelContext.save()
            if clearedLockdownThisTransaction {
                onLockdownClearedExit?()
            }
        } catch {
            modelContext.delete(insertedActivityLog)
            stat.currentXP -= delta
            quest.lastCompleted = previousCompleted
            profile.lockdownEpicCompletions = previousEpic
            profile.lockdownHardCompletions = previousHard
            profile.isInLockdown = previousInLockdown
            profile.lockdownEpisodeStart = previousLockdownEpisodeStart
            profile.currentHP = previousHP
        }
    }
}
