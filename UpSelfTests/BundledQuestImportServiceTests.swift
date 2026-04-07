//
//  BundledQuestImportServiceTests.swift
//  UpSelfTests
//

import Foundation
import SwiftData
import Testing
@testable import UpSelf

struct BundledQuestImportServiceTests {

    private func setupTestContext() throws -> (ModelContext, UserProfile) {
        let schema = Schema([
            UserProfile.self,
            CharacterStat.self,
            Quest.self,
            ActivityLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let profile = UserProfile(
            currentHP: 100,
            maxHP: 100,
            lastMissedDailyEvaluationDate: nil
        )
        context.insert(profile)
        try context.save()

        return (context, profile)
    }

    @Test @MainActor
    func importPack_insertsQuests() throws {
        let (context, profile) = try setupTestContext()
        let service = BundledQuestImportService()

        try service.importPack(.vitality, context: context, profile: profile)

        let quests = try context.fetch(FetchDescriptor<Quest>())
        #expect(!quests.isEmpty)
        #expect(quests.allSatisfy { $0.statKindRawValue == CharacterAttribute.vitality.rawValue })
        #expect(quests.allSatisfy { $0.user?.id == profile.id })
    }

    @Test @MainActor
    func importPack_isIdempotent() throws {
        let (context, profile) = try setupTestContext()
        let service = BundledQuestImportService()

        // First import
        try service.importPack(.vitality, context: context, profile: profile)
        let countAfterFirstImport = try context.fetch(FetchDescriptor<Quest>()).count

        // Second import
        try service.importPack(.vitality, context: context, profile: profile)
        let countAfterSecondImport = try context.fetch(FetchDescriptor<Quest>()).count

        #expect(countAfterFirstImport == countAfterSecondImport)
    }

    @Test @MainActor
    func importPack_preservesExistingQuests_onReimport() throws {
        let (context, profile) = try setupTestContext()
        let service = BundledQuestImportService()

        // Import first time
        try service.importPack(.vitality, context: context, profile: profile)
        let allQuests = try context.fetch(FetchDescriptor<Quest>())
        guard let firstQuest = allQuests.first else {
            Issue.record("No quests imported from vitality pack")
            return
        }

        // Delete one quest
        context.delete(firstQuest)
        try context.save()

        // Reimport
        try service.importPack(.vitality, context: context, profile: profile)
        let questsAfterReimport = try context.fetch(FetchDescriptor<Quest>())

        // The deleted quest should NOT be recreated (per-quest idempotency means it's only added if not found)
        // Actually, with per-quest check, if we delete it, reimport should skip it because the remaining ones exist
        // So the count should stay the same.
        #expect(questsAfterReimport.count == allQuests.count - 1)
    }

    @Test @MainActor
    func importMultiplePacks_separatesByAttribute() throws {
        let (context, profile) = try setupTestContext()
        let service = BundledQuestImportService()

        try service.importPack(.vitality, context: context, profile: profile)
        try service.importPack(.mastery, context: context, profile: profile)

        let quests = try context.fetch(FetchDescriptor<Quest>())
        let vitalityQuests = quests.filter { $0.statKindRawValue == CharacterAttribute.vitality.rawValue }
        let masteryQuests = quests.filter { $0.statKindRawValue == CharacterAttribute.mastery.rawValue }

        #expect(!vitalityQuests.isEmpty)
        #expect(!masteryQuests.isEmpty)
    }
}
