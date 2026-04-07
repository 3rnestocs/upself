//
//  BundledQuestImportService.swift
//  UpSelf
//
//  Imports quests from bundled JSON into SwiftData.
//  Per-quest idempotency: skips quests with matching title + statKind, allows partial re-import.
//

import Foundation
import SwiftData

protocol BundledQuestImportServiceProtocol: Sendable {
    func importPack(_ pack: BundledQuestPack, context: ModelContext, profile: UserProfile) throws
}

final class BundledQuestImportService: BundledQuestImportServiceProtocol, Sendable {
    func importPack(_ pack: BundledQuestPack, context: ModelContext, profile: UserProfile) throws {
        let blueprints = try BundledQuestCatalog.load(pack)

        // Fetch all existing quests to check idempotency
        let descriptor = FetchDescriptor<Quest>()
        let existingQuests = try context.fetch(descriptor)
        let existingTitlesByAttribute: [String: Set<String>] = existingQuests.reduce(into: [:]) { dict, quest in
            dict[quest.statKindRawValue, default: []].insert(quest.title)
        }

        for blueprint in blueprints {
            // Per-quest idempotency: skip if this title already exists for this attribute
            let attributeKey = blueprint.attribute.rawValue
            if existingTitlesByAttribute[attributeKey]?.contains(blueprint.title) == true {
                continue
            }

            // Insert new quest
            let quest = Quest(
                title: blueprint.title,
                statKind: blueprint.attribute,
                rewardXP: blueprint.rewardXP,
                isDaily: blueprint.isDaily
            )
            quest.user = profile
            context.insert(quest)
        }

        try context.save()
    }
}
