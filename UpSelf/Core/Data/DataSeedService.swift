//
//  DataSeedService.swift
//  UpSelf
//
//  Ensures first-launch data: one UserProfile and six CharacterStat rows.
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

            let profile = UserProfile(currentHP: 100, maxHP: 100)
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
