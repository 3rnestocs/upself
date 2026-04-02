//
//  MissedDailyPenaltyService.swift
//  UpSelf
//
//  On each app activation, evaluates **past** calendar days (through yesterday) for daily quests
//  not completed on their due day; applies HP loss and `ActivityLog` rows.
//

import Foundation
import SwiftData

enum MissedDailyPenaltyService {

    /// HP removed per daily quest missed for one calendar day (tunable).
    static let hpPerMissedDailyQuest = 10

    /// Run when the scene becomes active. Updates `lastAppOpen` and the missed-daily watermark.
    @MainActor
    static func evaluateIfNeeded(context: ModelContext) throws {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else { return }

        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        guard let profile = try context.fetch(descriptor).first else { return }

        if profile.lastMissedDailyEvaluationDate == nil {
            profile.lastMissedDailyEvaluationDate = yesterdayStart
            profile.lastAppOpen = now
            try context.save()
            return
        }

        var lastEval = calendar.startOfDay(for: profile.lastMissedDailyEvaluationDate!)
        var day = calendar.date(byAdding: .day, value: 1, to: lastEval)!

        while day <= yesterdayStart {
            let dailies = profile.quests.filter(\.isDaily)
            for quest in dailies {
                guard !isQuestCompleted(quest, on: day, calendar: calendar) else { continue }
                let loss = min(hpPerMissedDailyQuest, profile.currentHP)
                guard loss > 0 else { continue }

                profile.currentHP -= loss
                let dayLabel = day.formatted(date: .abbreviated, time: .omitted)
                let message = L10n.ActivityLogCopy.missedDailyMessage(
                    questTitle: quest.title,
                    dayLabel: dayLabel,
                    hp: loss
                )
                ActivityLogService.insertHPLoss(context: context, profile: profile, message: message)
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }

        profile.lastMissedDailyEvaluationDate = yesterdayStart
        profile.lastAppOpen = now
        try context.save()
    }

    private static func isQuestCompleted(_ quest: Quest, on dayStart: Date, calendar: Calendar) -> Bool {
        guard let completed = quest.lastCompleted else { return false }
        return calendar.isDate(completed, inSameDayAs: dayStart)
    }
}
