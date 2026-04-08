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
    func importBlueprints(_ blueprints: [BundledQuestBlueprint], context: ModelContext, profile: UserProfile) throws
}

final class BundledQuestImportService: BundledQuestImportServiceProtocol, Sendable {

    func importPack(_ pack: BundledQuestPack, context: ModelContext, profile: UserProfile) throws {
        let blueprints = try BundledQuestCatalog.load(pack)
        try importBlueprints(blueprints, context: context, profile: profile)
    }

    func importBlueprints(_ blueprints: [BundledQuestBlueprint], context: ModelContext, profile: UserProfile) throws {
        let existingQuests = try context.fetch(FetchDescriptor<Quest>())
        let existingTitlesByAttribute: [String: Set<String>] = existingQuests.reduce(into: [:]) { dict, quest in
            dict[quest.statKindRawValue, default: []].insert(quest.title)
        }

        for blueprint in blueprints {
            let attributeKey = blueprint.attribute.rawValue
            if existingTitlesByAttribute[attributeKey]?.contains(blueprint.title) == true {
                continue
            }
            let quest = Quest(
                title: blueprint.title,
                statKind: blueprint.attribute,
                rewardXP: blueprint.rewardXP,
                weeklyTarget: blueprint.weeklyTarget,
                isGoal: blueprint.isGoal
            )
            quest.user = profile
            context.insert(quest)
        }

        try context.save()
    }
}
