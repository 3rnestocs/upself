//
//  LocalAppResetService.swift
//  UpSelf
//
//  Wipes SwiftData user content, clears app UserDefaults, and re-seeds defaults.
//

import Foundation
import SwiftData

protocol LocalAppResetServiceProtocol: AnyObject {
    func resetAllLocalState(context: ModelContext) throws
}

/// Deletes all `UserProfile` rows (cascade removes related models), clears standard `UserDefaults` for the app, resets `GameClock`, then runs `DataSeedService`.
final class LocalAppResetService: LocalAppResetServiceProtocol {

    private let seedService: DataSeedServiceProtocol
    private let gameClock: GameClock

    init(
        seedService: DataSeedServiceProtocol = DependencyContainer[\.dataSeedService],
        gameClock: GameClock = DependencyContainer[\.gameClock]
    ) {
        self.seedService = seedService
        self.gameClock = gameClock
    }

    func resetAllLocalState(context: ModelContext) throws {
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        for profile in profiles {
            context.delete(profile)
        }
        try context.save()

        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        gameClock.dayOffset = 0

        seedService.seedIfNeeded(context: context)
        try context.save()
    }
}
