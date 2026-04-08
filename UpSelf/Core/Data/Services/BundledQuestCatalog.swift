//
//  BundledQuestCatalog.swift
//  UpSelf
//
//  Loads and decodes bundled quest JSON files from Core/Resources/Bundle/.
//  Each file (e.g., vitality.json) defines quests for one CharacterAttribute.
//

import Foundation
import os

enum BundledQuestPack: String, CaseIterable, Sendable {
    case vitality
    case logistics
    case mastery
    case charisma
    case willpower
    case economy

    var resourceName: String { self.rawValue }

    var attribute: CharacterAttribute {
        CharacterAttribute(rawValue: self.rawValue)!
    }
}

struct BundledQuestDefinition: Codable, Sendable {
    let title: String
    let tier: String
    let description: String?
    /// How many times per week this quest must be completed (nil = freeform or goal).
    let weeklyTarget: Int?
    /// `true` = once-ever milestone.
    let isGoal: Bool
}

struct BundledQuestFile: Codable, Sendable {
    let quests: [BundledQuestDefinition]
}

struct BundledQuestBlueprint: Sendable {
    let definition: BundledQuestDefinition
    let attribute: CharacterAttribute
    let rewardTier: QuestRewardTier

    var title: String        { definition.title }
    var rewardXP: Int        { rewardTier.xp }
    var weeklyTarget: Int?   { definition.weeklyTarget }
    var isGoal: Bool         { definition.isGoal }
}

enum BundledQuestCatalogError: Error, Sendable {
    case fileNotFound(BundledQuestPack)
    case decodingFailed(BundledQuestPack, underlying: Error)
}

final class BundledQuestCatalog: Sendable {
    static func load(_ pack: BundledQuestPack) throws -> [BundledQuestBlueprint] {
        guard let url = Bundle.main.url(forResource: pack.resourceName, withExtension: "json") else {
            throw BundledQuestCatalogError.fileNotFound(pack)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        let file: BundledQuestFile
        do {
            file = try decoder.decode(BundledQuestFile.self, from: data)
        } catch {
            throw BundledQuestCatalogError.decodingFailed(pack, underlying: error)
        }

        var blueprints: [BundledQuestBlueprint] = []
        let logger = Logger(subsystem: "com.upself.bundled-quests", category: "catalog")

        for definition in file.quests {
            guard let rewardTier = QuestRewardTier(rawValue: definition.tier) else {
                logger.warning("Skipping quest '\(definition.title)' in pack \(pack.rawValue): unrecognized tier '\(definition.tier)'")
                continue
            }
            blueprints.append(BundledQuestBlueprint(
                definition: definition,
                attribute: pack.attribute,
                rewardTier: rewardTier
            ))
        }

        return blueprints
    }
}
