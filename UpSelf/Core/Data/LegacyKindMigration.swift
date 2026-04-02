//
//  LegacyKindMigration.swift
//  UpSelf
//
//  One-shot normalization of stat / quest kind strings after renames or locale-specific seeds.
//

import Foundation
import SwiftData

enum LegacyKindMigration {
    static func normalizeAll(context: ModelContext) {
        do {
            let stats = try context.fetch(FetchDescriptor<CharacterStat>())
            for stat in stats {
                let n = CharacterAttribute.normalizedStorage(stat.kindRawValue)
                if stat.kindRawValue != n {
                    stat.kindRawValue = n
                }
            }

            let quests = try context.fetch(FetchDescriptor<Quest>())
            for quest in quests {
                let n = CharacterAttribute.normalizedStorage(quest.statKindRawValue)
                if quest.statKindRawValue != n {
                    quest.statKindRawValue = n
                }
            }

            try context.save()
        } catch {
            assertionFailure("LegacyKindMigration failed: \(error)")
        }
    }
}
