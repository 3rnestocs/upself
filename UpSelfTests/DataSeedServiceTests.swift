//
//  DataSeedServiceTests.swift
//  UpSelfTests
//

import SwiftData
import Testing
@testable import UpSelf

struct DataSeedServiceTests {

    @Test @MainActor func seedIfNeeded_isIdempotent() throws {
        let schema = Schema([
            UserProfile.self,
            CharacterStat.self,
            Quest.self,
            ActivityLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let service: DataSeedServiceProtocol = DataSeedService()
        service.seedIfNeeded(context: context)
        service.seedIfNeeded(context: context)

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        let stats = try context.fetch(FetchDescriptor<CharacterStat>())
        #expect(stats.count == CharacterAttribute.allCases.count)
        let quests = try context.fetch(FetchDescriptor<Quest>())
        #expect(!quests.isEmpty)
    }
}
