//
//  LockdownPolicyTests.swift
//  UpSelfTests
//

import Foundation
import Testing
@testable import UpSelf

struct LockdownPolicyTests {

    @Test func allows_createQuest_whenNotInLockdown() {
        #expect(LockdownPolicy.allows(.createQuest, isInLockdown: false))
    }

    @Test func disallows_createQuest_whenInLockdown() {
        #expect(!LockdownPolicy.allows(.createQuest, isInLockdown: true))
    }

    @Test func allows_easyQuestCompletion_whenNotInLockdown() {
        #expect(LockdownPolicy.allows(.completeQuest(tier: .easy), isInLockdown: false))
    }

    @Test func disallows_easyQuestCompletion_whenInLockdown() {
        #expect(!LockdownPolicy.allows(.completeQuest(tier: .easy), isInLockdown: true))
    }

    @Test func allows_hardAndEpicCompletion_whenInLockdown() {
        #expect(LockdownPolicy.allows(.completeQuest(tier: .hard), isInLockdown: true))
        #expect(LockdownPolicy.allows(.completeQuest(tier: .epic), isInLockdown: true))
    }

    @Test func shouldClearLockdown_whenEpicMinimumMet() {
        #expect(LockdownPolicy.shouldClearLockdown(epicCompletions: 1, hardCompletions: 0, minEpicToClear: 1, minHardToClear: 2))
    }

    @Test func shouldClearLockdown_whenHardMinimumMet() {
        #expect(LockdownPolicy.shouldClearLockdown(epicCompletions: 0, hardCompletions: 2, minEpicToClear: 1, minHardToClear: 2))
    }

    @Test func shouldNotClearLockdown_whenMinimumsAreZero() {
        #expect(!LockdownPolicy.shouldClearLockdown(epicCompletions: 5, hardCompletions: 5, minEpicToClear: 0, minHardToClear: 0))
    }

    @Test func repairInvalidRecoveryMinimums_setsDefaultsWhenBothZero() {
        let profile = UserProfile(
            lockdownMinEpicQuestsToClear: 0,
            lockdownMinHardQuestsToClear: 0
        )
        LockdownPolicy.repairInvalidRecoveryMinimums(profile)
        #expect(profile.lockdownMinEpicQuestsToClear == 1)
        #expect(profile.lockdownMinHardQuestsToClear == 2)
    }

    @Test func repairInvalidRecoveryMinimums_doesNotChangeValidMinimums() {
        let profile = UserProfile(
            lockdownMinEpicQuestsToClear: 2,
            lockdownMinHardQuestsToClear: 3
        )
        LockdownPolicy.repairInvalidRecoveryMinimums(profile)
        #expect(profile.lockdownMinEpicQuestsToClear == 2)
        #expect(profile.lockdownMinHardQuestsToClear == 3)
    }
}
