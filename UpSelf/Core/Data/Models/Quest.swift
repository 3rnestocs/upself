//
//  Quest.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//

import Foundation
import SwiftData

@Model
final class Quest {
    @Attribute(.unique) var id: UUID
    var title: String
    /// Persisted `CharacterAttribute.rawValue`.
    var statKindRawValue: String
    /// Encodes `QuestRewardTier.xp` — canonical values **6 / 10 / 15 / 30** (progress units).
    var rewardXP: Int

    // MARK: - Schedule

    /// How many times per week this quest must be completed to avoid HP penalty.
    /// - `nil` → freeform or goal (no commitment)
    /// - `1…7` → committed; penalty evaluated daily (7) or weekly on Monday (<7)
    var weeklyTarget: Int?

    /// `true` → once-ever milestone; completion is permanent. `weeklyTarget` must be `nil`.
    var isGoal: Bool

    // MARK: - Completion tracking

    var lastCompleted: Date?

    /// Number of completions logged in the week identified by `weeklyCompletionWeekOf`.
    /// Resets to 1 on the first completion of a new week.
    var weeklyCompletionCount: Int

    /// Start-of-week (Monday 00:00 local) that `weeklyCompletionCount` belongs to.
    var weeklyCompletionWeekOf: Date?

    var user: UserProfile?

    // MARK: - Computed helpers

    var isCommitted: Bool { weeklyTarget != nil }
    var isFreeform: Bool  { weeklyTarget == nil && !isGoal }

    var statKind: CharacterAttribute? {
        CharacterAttribute(rawValue: statKindRawValue)
    }

    var rewardTier: QuestRewardTier? {
        QuestRewardTier(xp: rewardXP)
    }

    init(id: UUID = UUID(),
         title: String,
         statKind: CharacterAttribute,
         rewardXP: Int = QuestRewardTier.easy.xp,
         weeklyTarget: Int? = QuestTargetDays.fullWeek.rawValue,
         isGoal: Bool = false) {
        self.id = id
        self.title = title
        self.statKindRawValue = statKind.rawValue
        self.rewardXP = rewardXP
        self.weeklyTarget = weeklyTarget
        self.isGoal = isGoal
        self.weeklyCompletionCount = 0
        self.weeklyCompletionWeekOf = nil
    }

    // MARK: - Completion state

    /// Whether the row should read as "done":
    /// - Goals: forever after first completion.
    /// - Committed / Freeform: only when completed **today**.
    func displayAsCompleted(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let completed = lastCompleted else { return false }
        if isGoal { return true }
        return calendar.isDate(completed, inSameDayAs: referenceDate)
    }

    /// Whether the user can earn XP again for this quest right now.
    /// - Goals: only if never completed.
    /// - Committed / Freeform: once per day; committed also checks weekly budget.
    func canComplete(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        if isGoal {
            return lastCompleted == nil
        }
        // Once-per-day gate
        if let completed = lastCompleted,
           calendar.isDate(completed, inSameDayAs: referenceDate) {
            return false
        }
        // Committed: also enforce weekly target ceiling
        if let target = weeklyTarget {
            return weeklyCount(for: referenceDate, calendar: calendar) < target
        }
        return true
    }

    /// Completions recorded for the calendar week that contains `referenceDate`.
    func weeklyCount(for date: Date, calendar: Calendar) -> Int {
        guard let weekOf = weeklyCompletionWeekOf else { return 0 }
        let thisWeekStart = calendar.mondayStart(for: date)
        guard calendar.isDate(weekOf, inSameDayAs: thisWeekStart) else { return 0 }
        return weeklyCompletionCount
    }

    // MARK: - Lockdown recovery list

    /// "Done" for the recovery list: same as `displayAsCompleted`, but only if `lastCompleted`
    /// is **on or after** the lockdown episode start.
    func recoveryListDisplayCompleted(referenceDate: Date, lockdownEpisodeStart: Date?, calendar: Calendar = .current) -> Bool {
        guard let start = lockdownEpisodeStart else {
            return displayAsCompleted(referenceDate: referenceDate, calendar: calendar)
        }
        guard displayAsCompleted(referenceDate: referenceDate, calendar: calendar) else { return false }
        guard let completed = lastCompleted else { return false }
        return completed >= start
    }

    /// Whether this hard/epic quest can be completed for recovery.
    /// Ignores a completion that happened before the lockdown episode started.
    func recoveryListCanComplete(referenceDate: Date, lockdownEpisodeStart: Date?, calendar: Calendar = .current) -> Bool {
        guard let start = lockdownEpisodeStart else {
            return canComplete(referenceDate: referenceDate, calendar: calendar)
        }
        guard rewardTier == .hard || rewardTier == .epic else {
            return canComplete(referenceDate: referenceDate, calendar: calendar)
        }
        // Goals (hard/epic in new model): can complete if never done or last completion was before episode.
        // Committed hard/epic (legacy): handle same-day-before-episode edge case.
        if isCommitted {
            guard let completed = lastCompleted else { return true }
            if calendar.isDate(completed, inSameDayAs: referenceDate) {
                return completed < start
            }
            return true
        }
        guard let completed = lastCompleted else { return true }
        return completed < start
    }
}
