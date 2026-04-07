//
//  DataSeedService.swift
//  UpSelf
//
//  Ensures first-launch data: one UserProfile and six CharacterStat rows.
//  Default quests are not seeded here; bundled JSON under `Core/Resources/Bundle/` is the source of truth (import flow TBD).
//

import Foundation
import SwiftData

protocol DataSeedServiceProtocol {
    func seedIfNeeded(context: ModelContext)
}

final class DataSeedService: DataSeedServiceProtocol {

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

            try context.save()
        } catch {
            assertionFailure("DataSeedService: seed failed — \(error)")
        }
    }
}
