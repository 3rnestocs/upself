//
//  QuestCompletionHelpersTests.swift
//  UpSelfTests
//

import Foundation
import Testing
@testable import UpSelf

struct QuestCompletionHelpersTests {

    private var utc: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    @Test func daily_displayAsCompleted_onlyWhenCompletedSameDay() throws {
        var cal = utc
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2)))
        let nextDay = try #require(cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: day)))

        let quest = Quest(title: "Daily", statKind: .vitality, rewardXP: QuestRewardTier.easy.xp, isDaily: true)
        quest.lastCompleted = day

        #expect(quest.displayAsCompleted(referenceDate: day, calendar: cal))
        #expect(!quest.displayAsCompleted(referenceDate: nextDay, calendar: cal))
    }

    @Test func daily_canComplete_falseAfterSameDayCompletion() throws {
        var cal = utc
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2)))
        let quest = Quest(title: "Daily", statKind: .vitality, rewardXP: QuestRewardTier.easy.xp, isDaily: true)
        quest.lastCompleted = day

        #expect(!quest.canComplete(referenceDate: day, calendar: cal))
    }

    @Test func oneOff_displayAsCompleted_staysTrueAfterFirstCompletion() throws {
        var cal = utc
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2)))
        let later = try #require(cal.date(byAdding: .day, value: 10, to: day))

        let quest = Quest(title: "One-off", statKind: .logistics, rewardXP: QuestRewardTier.regular.xp, isDaily: false)
        quest.lastCompleted = day

        #expect(quest.displayAsCompleted(referenceDate: later, calendar: cal))
        #expect(!quest.canComplete(referenceDate: later, calendar: cal))
    }

    @Test func recovery_hardDaily_canCompleteWhenCompletedEarlierSameDayBeforeEpisode() throws {
        var cal = utc
        let episodeStart = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2, hour: 12)))
        let morning = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2, hour: 9)))
        let ref = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2, hour: 18)))

        let quest = Quest(title: "Hard daily", statKind: .vitality, rewardXP: QuestRewardTier.hard.xp, isDaily: true)
        quest.lastCompleted = morning

        #expect(quest.recoveryListCanComplete(referenceDate: ref, lockdownEpisodeStart: episodeStart, calendar: cal))
    }
}
