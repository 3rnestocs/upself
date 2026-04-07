//
//  MissedDailyPenaltyService.swift
//  UpSelf
//
//  On each app activation, evaluates **past** calendar days (through yesterday). If the **daily set**
//  was not fully completed on a day, applies one HP loss for that day (not per quest).
//

import Foundation
import SwiftData

enum MissedDailyPenaltyService {

    /// HP removed when **any** daily remains incomplete for a past calendar day (once per day, not per quest).
    static let hpPerIncompleteDailyDay = 20

    /// Run when the scene becomes active. Updates `lastAppOpen` and the missed-daily watermark.
    /// - Returns: Total HP subtracted this run (for global UI); `0` if none.
    @MainActor
    @discardableResult
    static func evaluateIfNeeded(context: ModelContext, clock: GameClock) throws -> Int {
        let calendar = Calendar.current
        let now = clock.now
        let todayStart = calendar.startOfDay(for: now)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else { return 0 }

        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        guard let profile = try context.fetch(descriptor).first else { return 0 }

        // First install: do not back-penalize arbitrary history. Seed the watermark to **two days ago**
        // so the next line’s `day = lastEval + 1` equals **yesterday** and the loop can run.
        // (The old path set the watermark to *yesterday* and returned: then `day` became *today*, which is
        // never `<= yesterday`, so **yesterday was never evaluated** — penalties never applied.)
        if profile.lastMissedDailyEvaluationDate == nil {
            guard let twoDaysAgoStart = calendar.date(byAdding: .day, value: -2, to: todayStart) else { return 0 }
            profile.lastMissedDailyEvaluationDate = twoDaysAgoStart
            profile.lastAppOpen = now
            try DependencyContainer[\.lockdownEvaluationService].evaluate(context: context, now: now)
            try context.save()
            return 0
        }

        var totalHPLostThisRun = 0
        // `lastMissedDailyEvaluationDate` is guaranteed non-nil here: the nil branch above returns early.
        let lastEval = calendar.startOfDay(for: profile.lastMissedDailyEvaluationDate!)
        guard let initialDay = calendar.date(byAdding: .day, value: 1, to: lastEval) else { return 0 }
        var day = initialDay

        while day <= yesterdayStart {
            let dailies = profile.quests.filter(\.isDaily)
            if !dailies.isEmpty {
                let allDailiesCompletedThatDay = dailies.allSatisfy {
                    Self.isQuestCompletedOnCalendarDay($0, dayStart: day, calendar: calendar)
                }
                if !allDailiesCompletedThatDay {
                    let loss = min(hpPerIncompleteDailyDay, profile.currentHP)
                    if loss > 0 {
                        profile.currentHP -= loss
                        totalHPLostThisRun += loss
                        let dayLabel = day.formatted(date: .abbreviated, time: .omitted)
                        let message = L10n.ActivityLogCopy.missedDailySetMessage(dayLabel: dayLabel, hp: loss)
                        DependencyContainer[\.activityLogService].insertHPLoss(context: context, profile: profile, message: message)
                    }
                }
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }

        profile.lastMissedDailyEvaluationDate = yesterdayStart
        profile.lastAppOpen = now
        try DependencyContainer[\.lockdownEvaluationService].evaluate(context: context, now: now)
        try context.save()
        return totalHPLostThisRun
    }

    /// Whether `quest.lastCompleted` falls on the same calendar day as `dayStart` (missed-daily evaluation).
    static func isQuestCompletedOnCalendarDay(_ quest: Quest, dayStart: Date, calendar: Calendar) -> Bool {
        guard let completed = quest.lastCompleted else { return false }
        return calendar.isDate(completed, inSameDayAs: dayStart)
    }
}

#if DEBUG
extension MissedDailyPenaltyService {
    /// Resets the watermark to **two days before “game today”** so the **next** `evaluateIfNeeded` processes
    /// **yesterday** for penalties (matches first-install seeding; simulation helper).
    static func debugResetEvaluationWatermark(context: ModelContext, clock: GameClock) throws {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: clock.now)
        guard let twoDaysAgoStart = calendar.date(byAdding: .day, value: -2, to: todayStart) else { return }

        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        guard let profile = try context.fetch(descriptor).first else { return }
        profile.lastMissedDailyEvaluationDate = twoDaysAgoStart
        try context.save()
    }
}
#endif
