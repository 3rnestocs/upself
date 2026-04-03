//
//  ActivityLogService.swift
//  UpSelf
//
//  Inserts `ActivityLog` rows; copy comes from `L10n`.
//

import Foundation
import SwiftData

enum ActivityLogService {

    private static var eventTimestamp: Date {
        DependencyContainer[\.gameClock].now
    }

    /// Records an XP grant after attribute selection; no `save()` — caller saves once.
    static func insertXPGain(context: ModelContext, stat: CharacterStat, tier: QuestRewardTier) {
        guard let attribute = stat.kind, let profile = stat.user else { return }
        let message = L10n.ActivityLogCopy.xpGainMessage(xp: tier.xp, attribute: attribute)
        let log = ActivityLog(timestamp: eventTimestamp, message: message, kind: .xpGain, user: profile)
        context.insert(log)
    }

    /// XP from completing a specific persisted quest (title + attribute in copy).
    static func insertQuestXPGain(context: ModelContext, stat: CharacterStat, tier: QuestRewardTier, questTitle: String) {
        guard let attribute = stat.kind, let profile = stat.user else { return }
        let message = L10n.ActivityLogCopy.xpGainQuestMessage(
            xp: tier.xp,
            questTitle: questTitle,
            attribute: attribute
        )
        let log = ActivityLog(timestamp: eventTimestamp, message: message, kind: .xpGain, user: profile)
        context.insert(log)
    }

    static func insertHPLoss(context: ModelContext, profile: UserProfile, message: String) {
        let log = ActivityLog(timestamp: eventTimestamp, message: message, kind: .hpLoss, user: profile)
        context.insert(log)
    }
}
