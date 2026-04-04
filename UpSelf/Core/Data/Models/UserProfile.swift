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

    /// Epic-tier quests completed during the current lockdown episode (reset when lockdown starts).
    var lockdownEpicCompletions: Int
    /// Hard-tier quests completed during the current lockdown episode (reset when lockdown starts).
    var lockdownHardCompletions: Int
    /// Minimum epic completions to clear lockdown (`> 0` to count toward exit).
    var lockdownMinEpicQuestsToClear: Int
    /// Minimum hard completions to clear lockdown (`> 0` to count toward exit).
    var lockdownMinHardQuestsToClear: Int

    /// Wall-clock moment the current lockdown episode **started** (set on enter, cleared on exit). Used so recovery UI ignores completions from before lockdown.
    var lockdownEpisodeStart: Date?

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
         isInLockdown: Bool = false,
         lockdownEpicCompletions: Int = 0,
         lockdownHardCompletions: Int = 0,
         lockdownMinEpicQuestsToClear: Int = 1,
         lockdownMinHardQuestsToClear: Int = 2,
         lockdownEpisodeStart: Date? = nil) {
        self.id = id
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.lastAppOpen = lastAppOpen
        self.lastMissedDailyEvaluationDate = lastMissedDailyEvaluationDate
        self.isInLockdown = isInLockdown
        self.lockdownEpicCompletions = lockdownEpicCompletions
        self.lockdownHardCompletions = lockdownHardCompletions
        self.lockdownMinEpicQuestsToClear = lockdownMinEpicQuestsToClear
        self.lockdownMinHardQuestsToClear = lockdownMinHardQuestsToClear
        self.lockdownEpisodeStart = lockdownEpisodeStart
    }
}
