//
//  MissedDailyPenaltyService.swift
//  UpSelf
//
//  On each app activation, evaluates **past** calendar days (through yesterday).
//
//  Daily path   — quests with weeklyTarget == 7 must be completed every day.
//                 One HP loss per day where any 7/7 quest was missed.
//  Weekly path  — quests with weeklyTarget < 7 are checked every Monday for the
//                 previous Mon–Sun week. One HP loss per quest that fell short
//                 of its target.
//

import Foundation
import SwiftData

enum MissedDailyPenaltyService {

    /// HP removed when any 7/7 quest remains incomplete for a past calendar day.
    static let hpPerIncompleteDailyDay = 20

    /// HP removed per weekly-committed quest that missed its target for a past week.
    static let hpPerMissedWeeklyQuest = 20

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

        if profile.lastMissedDailyEvaluationDate == nil {
            guard let twoDaysAgoStart = calendar.date(byAdding: .day, value: -2, to: todayStart) else { return 0 }
            profile.lastMissedDailyEvaluationDate = twoDaysAgoStart
            profile.lastAppOpen = now
            try DependencyContainer[\.lockdownEvaluationService].evaluate(context: context, now: now)
            try context.save()
            return 0
        }

        var totalHPLostThisRun = 0
        let lastEval = calendar.startOfDay(for: profile.lastMissedDailyEvaluationDate!)
        guard let initialDay = calendar.date(byAdding: .day, value: 1, to: lastEval) else { return 0 }
        var day = initialDay

        while day <= yesterdayStart {
            // ── Daily path: 7/7 committed quests ──────────────────────────────────
            let dailyCommitted = profile.quests.filter { $0.weeklyTarget == 7 }
            if !dailyCommitted.isEmpty {
                let allCompleted = dailyCommitted.allSatisfy {
                    Self.isQuestCompletedOnCalendarDay($0, dayStart: day, calendar: calendar)
                }
                if !allCompleted {
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

            // ── Weekly path: <7/7 committed quests, evaluated every Monday ────────
            if calendar.isMonday(day) {
                guard let prevWeekMonday = calendar.date(byAdding: .weekOfYear, value: -1, to: day) else {
                    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                    day = nextDay
                    continue
                }

                let weeklyCommitted = profile.quests.filter {
                    guard let target = $0.weeklyTarget else { return false }
                    return target < 7
                }

                for quest in weeklyCommitted {
                    let completionsLastWeek: Int
                    if let weekOf = quest.weeklyCompletionWeekOf,
                       calendar.isDate(weekOf, inSameDayAs: prevWeekMonday) {
                        completionsLastWeek = quest.weeklyCompletionCount
                    } else {
                        completionsLastWeek = 0
                    }

                    let target = quest.weeklyTarget!
                    if completionsLastWeek < target {
                        let loss = min(hpPerMissedWeeklyQuest, profile.currentHP)
                        if loss > 0 {
                            profile.currentHP -= loss
                            totalHPLostThisRun += loss
                            let weekLabel = prevWeekMonday.formatted(date: .abbreviated, time: .omitted)
                            let message = L10n.ActivityLogCopy.missedDailySetMessage(dayLabel: weekLabel, hp: loss)
                            DependencyContainer[\.activityLogService].insertHPLoss(context: context, profile: profile, message: message)
                        }
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

    /// Whether `quest.lastCompleted` falls on the same calendar day as `dayStart`.
    static func isQuestCompletedOnCalendarDay(_ quest: Quest, dayStart: Date, calendar: Calendar) -> Bool {
        guard let completed = quest.lastCompleted else { return false }
        return calendar.isDate(completed, inSameDayAs: dayStart)
    }
}

#if DEBUG
extension MissedDailyPenaltyService {
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
