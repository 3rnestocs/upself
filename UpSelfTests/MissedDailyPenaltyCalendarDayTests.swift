//
//  MissedDailyPenaltyCalendarDayTests.swift
//  UpSelfTests
//

import Foundation
import Testing
@testable import UpSelf

struct MissedDailyPenaltyCalendarDayTests {

    private var utc: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    @Test func isQuestCompletedOnCalendarDay_trueWhenLastCompletedSameDay() throws {
        var cal = utc
        let dayStart = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let noon = try #require(cal.date(byAdding: .hour, value: 12, to: dayStart))

        let quest = Quest(title: "Q", statKind: .vitality, isDaily: true)
        quest.lastCompleted = noon

        #expect(MissedDailyPenaltyService.isQuestCompletedOnCalendarDay(quest, dayStart: dayStart, calendar: cal))
    }

    @Test func isQuestCompletedOnCalendarDay_falseWhenNilOrDifferentDay() throws {
        var cal = utc
        let dayStart = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let otherDay = try #require(cal.date(byAdding: .day, value: -1, to: dayStart))

        let empty = Quest(title: "Q", statKind: .vitality, isDaily: true)
        #expect(!MissedDailyPenaltyService.isQuestCompletedOnCalendarDay(empty, dayStart: dayStart, calendar: cal))

        let quest = Quest(title: "Q", statKind: .vitality, isDaily: true)
        quest.lastCompleted = otherDay
        #expect(!MissedDailyPenaltyService.isQuestCompletedOnCalendarDay(quest, dayStart: dayStart, calendar: cal))
    }
}
