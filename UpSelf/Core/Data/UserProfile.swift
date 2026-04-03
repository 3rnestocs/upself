//
//  UserProfile.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//


import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var currentHP: Int
    var maxHP: Int
    var lastAppOpen: Date
    var isInLockdown: Bool

    /// Start of the last **calendar day** fully processed for missed-daily HP checks (see `MissedDailyPenaltyService`).
    /// `nil` = not set yet; first run seeds two days back so the next evaluation can process **yesterday** (no arbitrary backfill).
    var lastMissedDailyEvaluationDate: Date?
    
    @Relationship(deleteRule: .cascade) 
    var stats: [CharacterStat] = []

    @Relationship(deleteRule: .cascade, inverse: \Quest.user)
    var quests: [Quest] = []

    @Relationship(deleteRule: .cascade, inverse: \ActivityLog.user)
    var activityLogs: [ActivityLog] = []

    init(id: UUID = UUID(), 
         currentHP: Int = 100, 
         maxHP: Int = 100, 
         lastAppOpen: Date = .now,
         lastMissedDailyEvaluationDate: Date? = nil,
         isInLockdown: Bool = false) {
        self.id = id
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.lastAppOpen = lastAppOpen
        self.lastMissedDailyEvaluationDate = lastMissedDailyEvaluationDate
        self.isInLockdown = isInLockdown
    }
}
