//
//  ActivityLogService.swift
//  UpSelf
//
//  Inserts `ActivityLog` rows; copy comes from `L10n`.
//

import Foundation
import SwiftData

protocol ActivityLogServiceProtocol: AnyObject {
    func insertXPGain(context: ModelContext, stat: CharacterStat, tier: QuestRewardTier)
    @discardableResult
    func insertQuestXPGain(context: ModelContext, stat: CharacterStat, tier: QuestRewardTier, questTitle: String) -> ActivityLog?
    func insertHPLoss(context: ModelContext, profile: UserProfile, message: String)
}

final class ActivityLogService: ActivityLogServiceProtocol {

    private let gameClock: GameClock

    init(gameClock: GameClock) {
        self.gameClock = gameClock
    }

    private var eventTimestamp: Date { gameClock.now }

    /// Records an XP grant after attribute selection; no `save()` — caller saves once.
    func insertXPGain(context: ModelContext, stat: CharacterStat, tier: QuestRewardTier) {
        guard let attribute = stat.kind, let profile = stat.user else { return }
        let message = L10n.ActivityLogCopy.xpGainMessage(xp: tier.xp, attribute: attribute)
        let log = ActivityLog(timestamp: eventTimestamp, message: message, kind: .xpGain, user: profile)
        context.insert(log)
    }

    /// XP from completing a specific persisted quest (title + attribute in copy).
    /// Returns the inserted model so callers can `delete` it if a following `save()` fails.
    @discardableResult
    func insertQuestXPGain(context: ModelContext, stat: CharacterStat, tier: QuestRewardTier, questTitle: String) -> ActivityLog? {
        guard let attribute = stat.kind, let profile = stat.user else { return nil }
        let message = L10n.ActivityLogCopy.xpGainQuestMessage(
            xp: tier.xp,
            questTitle: questTitle,
            attribute: attribute
        )
        let log = ActivityLog(timestamp: eventTimestamp, message: message, kind: .xpGain, user: profile)
        context.insert(log)
        return log
    }

    func insertHPLoss(context: ModelContext, profile: UserProfile, message: String) {
        let log = ActivityLog(timestamp: eventTimestamp, message: message, kind: .hpLoss, user: profile)
        context.insert(log)
    }
}
