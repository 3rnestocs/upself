//
//  LockdownCapability.swift
//  UpSelf
//

import Foundation

/// Gateable behaviors while `UserProfile.isInLockdown` is true. Add a case when a new surface needs policy.
enum LockdownCapability: Equatable {
    case dailyBrief
    case createQuest
    case completeQuest(tier: QuestRewardTier)
}
