//
//  LockdownEvaluationService.swift
//  UpSelf
//
//  Single place that decides whether to **enter** lockdown from HP ratio.
//  Exit is handled in `QuestLogViewModel` via `QuestCompletionService`.
//

import Foundation
import SwiftData

protocol LockdownEvaluationServiceProtocol: AnyObject {
    @MainActor
    func evaluate(context: ModelContext, now: Date) throws
}

@MainActor
final class LockdownEvaluationService: LockdownEvaluationServiceProtocol {

    func evaluate(context: ModelContext, now: Date) throws {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        guard let profile = try context.fetch(descriptor).first else { return }

        LockdownPolicy.repairInvalidRecoveryMinimums(profile)

        let maxHP = max(profile.maxHP, 1)
        let ratio = Double(profile.currentHP) / Double(maxHP)

        if ratio < LockdownPolicy.enterLockdownHPRatio, !profile.isInLockdown {
            profile.isInLockdown = true
            profile.lockdownEpicCompletions = 0
            profile.lockdownHardCompletions = 0
            profile.lockdownEpisodeStart = now
        }
    }
}
