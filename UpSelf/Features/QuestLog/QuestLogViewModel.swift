//
//  QuestLogViewModel.swift
//  UpSelf
//
//  Quest list and completion; routing stays in AppCoordinator.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class QuestLogViewModel {

    private let modelContext: ModelContext
    private let gameClock: GameClock
    private let completionService: QuestCompletionServiceProtocol

    /// Pop the nav stack when lockdown engages (this screen must not stay visible while in lockdown).
    var onLockdownEngagedExit: (() -> Void)?

    /// System alert when the user tries to complete a tier blocked in lockdown.
    var onPresentLockdownTierBlockedAlert: (() -> Void)?

    /// Quest log instructions presented as a system alert.
    var onPresentQuestLogInstructions: (() -> Void)?

    // MARK: - Display state

    /// Filtered and sorted quest list for the current filter tab. Populated by `refreshQuests(...)`.
    var visibleQuests: [Quest] = []

    init(
        modelContext: ModelContext,
        gameClock: GameClock,
        completionService: QuestCompletionServiceProtocol = DependencyContainer[\.questCompletionService]
    ) {
        self.modelContext = modelContext
        self.gameClock = gameClock
        self.completionService = completionService
    }

    // MARK: - Data refresh

    func refreshQuests(allQuests: [Quest], profiles: [UserProfile], filter: QuestLogFilter, clock: GameClock) {
        guard let id = profiles.first?.id else {
            visibleQuests = []
            return
        }
        let ref = clock.now
        let subset = allQuests.filter { quest in
            guard quest.user?.id == id else { return false }
            switch filter {
            case .daily:  return quest.isDaily
            case .oneOff: return !quest.isDaily
            }
        }
        visibleQuests = subset.sorted { a, b in
            let ad = a.displayAsCompleted(referenceDate: ref)
            let bd = b.displayAsCompleted(referenceDate: ref)
            if ad != bd { return !ad && bd }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    // MARK: - Navigation

    func presentQuestLogInstructions() {
        onPresentQuestLogInstructions?()
    }

    // MARK: - Quest completion

    /// Delegates to `QuestCompletionService` and routes the result to the appropriate callback.
    func completePersistedQuest(_ quest: Quest) {
        guard let result = try? completionService.complete(quest, context: modelContext) else { return }
        switch result {
        case .completed, .completedAndClearedLockdown:
            // Lockdown cannot clear from QuestLog (blocked tiers prevent it); .completedAndClearedLockdown
            // is handled by RecoveryQuestListViewModel.
            break
        case .tierBlockedInLockdown:
            onPresentLockdownTierBlockedAlert?()
        case .notEligible:
            break
        }
    }
}
