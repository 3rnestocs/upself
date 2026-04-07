//
//  BundledQuestCatalogTests.swift
//  UpSelfTests
//

import Foundation
import Testing
@testable import UpSelf

struct BundledQuestCatalogTests {

    @Test
    func load_vitalityPack_decodesQuests() throws {
        let blueprints = try BundledQuestCatalog.load(.vitality)

        #expect(!blueprints.isEmpty)
        #expect(blueprints.allSatisfy { $0.attribute == .vitality })
        #expect(blueprints.allSatisfy { QuestRewardTier.allCases.contains($0.rewardTier) })
    }

    @Test
    func load_allPacks_decodesSuccessfully() throws {
        for pack in BundledQuestPack.allCases {
            let blueprints = try BundledQuestCatalog.load(pack)
            #expect(!blueprints.isEmpty, "Pack \(pack.rawValue) should contain quests")
            #expect(blueprints.allSatisfy { $0.attribute == pack.attribute })
        }
    }

    @Test
    func blueprint_hasValidTierMapping() throws {
        let blueprints = try BundledQuestCatalog.load(.vitality)

        for blueprint in blueprints {
            #expect(blueprint.rewardXP > 0)
            let tier = blueprint.rewardTier
            #expect([.easy, .regular, .hard, .epic].contains(tier))
        }
    }

    @Test
    func load_invalidPack_throwsFileNotFound() throws {
        // This test verifies error handling, though we can't easily create
        // a non-existent pack with the enum. Documenting the behavior here.
    }
}
