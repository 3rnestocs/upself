//
//  LockdownPolicy.swift
//  UpSelf
//

import Foundation

/// Pure rules for what is allowed during lockdown. Views and VMs query this instead of branching on `isInLockdown` alone.
enum LockdownPolicy {

    /// If both minimums are 0 (invalid / legacy store), restore defaults so the user can always exit lockdown.
    static func repairInvalidRecoveryMinimums(_ profile: UserProfile) {
        if profile.lockdownMinEpicQuestsToClear == 0 && profile.lockdownMinHardQuestsToClear == 0 {
            profile.lockdownMinEpicQuestsToClear = 1
            profile.lockdownMinHardQuestsToClear = 2
        }
    }

    /// HP ratio below which the UI may show the low-HP heartbeat (visual only).
    static let heartbeatHPRatio: Double = 0.50

    /// HP ratio below which lockdown **enters** (if not already active).
    static let enterLockdownHPRatio: Double = 0.30

    static func allows(_ capability: LockdownCapability, isInLockdown: Bool) -> Bool {
        guard isInLockdown else { return true }
        switch capability {
        case .dailyBrief, .createQuest:
            return false
        case .completeQuest(let tier):
            switch tier {
            case .easy, .regular:
                return false
            case .hard, .epic:
                return true
            }
        }
    }

    /// Whether completing this quest tier should clear lockdown (after incrementing counters).
    static func shouldClearLockdown(
        epicCompletions: Int,
        hardCompletions: Int,
        minEpicToClear: Int,
        minHardToClear: Int
    ) -> Bool {
        let epicMet = minEpicToClear > 0 && epicCompletions >= minEpicToClear
        let hardMet = minHardToClear > 0 && hardCompletions >= minHardToClear
        return epicMet || hardMet
    }
}
