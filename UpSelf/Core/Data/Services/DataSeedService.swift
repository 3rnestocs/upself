//
//  DataSeedService.swift
//  UpSelf
//
//  Ensures first-launch data: one UserProfile, six CharacterStat rows, and default Quests.
//

import Foundation
import SwiftData

protocol DataSeedServiceProtocol {
    func seedIfNeeded(context: ModelContext)
}

final class DataSeedService: DataSeedServiceProtocol {

    private typealias SeedRow = (title: LocalizedStringResource, attribute: CharacterAttribute, tier: QuestRewardTier, isDaily: Bool)

    /// Preset quests for immediate core-loop feedback (titles via `L10n.SeedQuests` + String Catalog).
    private static let seedQuestRows: [SeedRow] = [
        (L10n.SeedQuests.vitalityWater, .vitality, .easy, true),
        (L10n.SeedQuests.vitalityTrain45, .vitality, .regular, true),
        (L10n.SeedQuests.vitalityRun5k, .vitality, .hard, true),
        (L10n.SeedQuests.logisticsBed, .logistics, .easy, true),
        (L10n.SeedQuests.logisticsWeekPlan, .logistics, .regular, false),
        (L10n.SeedQuests.logisticsDeepClean, .logistics, .hard, false),
        (L10n.SeedQuests.masteryRead10, .mastery, .regular, true),
        (L10n.SeedQuests.masteryStudy2h, .mastery, .hard, true),
        (L10n.SeedQuests.vitalityBrush3x, .vitality, .easy, true),
        (L10n.SeedQuests.vitalityMealOnTime, .vitality, .easy, true),
        (L10n.SeedQuests.masteryUniversityStudy, .mastery, .regular, false),
        (L10n.SeedQuests.economyWork2hUninterrupted, .economy, .regular, false),
        (L10n.SeedQuests.masteryUpSelf1h, .mastery, .regular, true),
        (L10n.SeedQuests.charismaActivityClaudia, .charisma, .regular, true),
        (L10n.SeedQuests.willpowerGamingSchedule, .willpower, .easy, false),
        (L10n.SeedQuests.willpowerSeriesSchedule, .willpower, .easy, false),
        (L10n.SeedQuests.masteryEnglishPractice, .mastery, .regular, true),
        (L10n.SeedQuests.logisticsMealPrep, .logistics, .hard, false),
        (L10n.SeedQuests.willpowerColdShower, .willpower, .hard, true),
        (L10n.SeedQuests.willpowerMeditate10, .willpower, .regular, true),
        (L10n.SeedQuests.willpowerNoSugar, .willpower, .epic, true),
        (L10n.SeedQuests.economyTrackExpenses, .economy, .easy, true),
        (L10n.SeedQuests.economyNoDelivery, .economy, .hard, true),
        (L10n.SeedQuests.charismaCallFriend, .charisma, .regular, true)
    ]

    func seedIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1

        do {
            let existing = try context.fetch(descriptor)
            if !existing.isEmpty { return }

            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: Date())
            let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)
            let profile = UserProfile(
                currentHP: 100,
                maxHP: 100,
                lastMissedDailyEvaluationDate: yesterdayStart
            )
            context.insert(profile)

            for kind in CharacterAttribute.allCases {
                let stat = CharacterStat(kind: kind, currentXP: 0)
                stat.user = profile
                profile.stats.append(stat)
                context.insert(stat)
            }

            for row in Self.seedQuestRows {
                let title = String(localized: row.title)
                let quest = Quest(
                    title: title,
                    statKind: row.attribute,
                    rewardXP: row.tier.xp,
                    isDaily: row.isDaily
                )
                quest.user = profile
                context.insert(quest)
            }

            try context.save()
        } catch {
            assertionFailure("DataSeedService: seed failed — \(error)")
        }
    }
}
