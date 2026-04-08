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

    @Test func committed_displayAsCompleted_onlyWhenCompletedSameDay() throws {
        let cal = utc
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2)))
        let nextDay = try #require(cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: day)))

        let quest = Quest(title: "Committed", statKind: .vitality, rewardXP: QuestRewardTier.easy.xp, weeklyTarget: 7, isGoal: false)
        quest.lastCompleted = day

        #expect(quest.displayAsCompleted(referenceDate: day, calendar: cal))
        #expect(!quest.displayAsCompleted(referenceDate: nextDay, calendar: cal))
    }

    @Test func committed_canComplete_falseAfterSameDayCompletion() throws {
        let cal = utc
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2)))
        let quest = Quest(title: "Committed", statKind: .vitality, rewardXP: QuestRewardTier.easy.xp, weeklyTarget: 7, isGoal: false)
        quest.lastCompleted = day
        quest.weeklyCompletionCount = 1
        quest.weeklyCompletionWeekOf = cal.mondayStart(for: day)

        #expect(!quest.canComplete(referenceDate: day, calendar: cal))
    }

    @Test func committed_canComplete_falseWhenWeeklyTargetReached() throws {
        let cal = utc
        // Wednesday 2026-04-08 (weeklyTarget=3, already completed 3 times this week)
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 8)))
        let yesterday = try #require(cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: day)))

        let quest = Quest(title: "Training", statKind: .vitality, rewardXP: QuestRewardTier.regular.xp, weeklyTarget: 3, isGoal: false)
        quest.lastCompleted = yesterday
        quest.weeklyCompletionCount = 3
        quest.weeklyCompletionWeekOf = cal.mondayStart(for: day)

        #expect(!quest.canComplete(referenceDate: day, calendar: cal))
    }

    @Test func committed_canComplete_trueWhenWeeklyTargetNotYetReached() throws {
        let cal = utc
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 8)))
        let yesterday = try #require(cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: day)))

        let quest = Quest(title: "Training", statKind: .vitality, rewardXP: QuestRewardTier.regular.xp, weeklyTarget: 3, isGoal: false)
        quest.lastCompleted = yesterday
        quest.weeklyCompletionCount = 2
        quest.weeklyCompletionWeekOf = cal.mondayStart(for: day)

        #expect(quest.canComplete(referenceDate: day, calendar: cal))
    }

    @Test func freeform_displayAsCompleted_resetsNextDay() throws {
        let cal = utc
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2)))
        let later = try #require(cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: day)))

        let quest = Quest(title: "Freeform", statKind: .logistics, rewardXP: QuestRewardTier.easy.xp, weeklyTarget: nil, isGoal: false)
        quest.lastCompleted = day

        #expect(quest.displayAsCompleted(referenceDate: day, calendar: cal))
        #expect(!quest.displayAsCompleted(referenceDate: later, calendar: cal))
        #expect(quest.canComplete(referenceDate: later, calendar: cal))
    }

    @Test func goal_displayAsCompleted_staysTrueAfterFirstCompletion() throws {
        let cal = utc
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2)))
        let later = try #require(cal.date(byAdding: .day, value: 10, to: day))

        let quest = Quest(title: "Goal", statKind: .logistics, rewardXP: QuestRewardTier.regular.xp, weeklyTarget: nil, isGoal: true)
        quest.lastCompleted = day

        #expect(quest.displayAsCompleted(referenceDate: later, calendar: cal))
        #expect(!quest.canComplete(referenceDate: later, calendar: cal))
    }

    @Test func recovery_hardGoal_canCompleteWhenCompletedBeforeEpisode() throws {
        let cal = utc
        let episodeStart = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2, hour: 12)))
        let morning = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2, hour: 9)))
        let ref = try #require(cal.date(from: DateComponents(year: 2026, month: 4, day: 2, hour: 18)))

        let quest = Quest(title: "Hard goal", statKind: .vitality, rewardXP: QuestRewardTier.hard.xp, weeklyTarget: nil, isGoal: true)
        quest.lastCompleted = morning

        #expect(quest.recoveryListCanComplete(referenceDate: ref, lockdownEpisodeStart: episodeStart, calendar: cal))
    }
}
