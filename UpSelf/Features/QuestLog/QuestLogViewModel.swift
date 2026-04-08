//
//  QuestLogViewModel.swift
//  UpSelf
//
//  Quest list and completion; routing stays in AppNavigator (wired by AppRootView).
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

    /// Fires once after the 3rd quest completion to prompt the difficulty self-report.
    var onShouldShowDifficultyCheck: (() -> Void)?

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
            if !visibleQuests.isEmpty { visibleQuests = [] }
            return
        }
        let ref = clock.now
        let subset = allQuests.filter { quest in
            guard quest.user?.id == id else { return false }
            switch filter {
            case .daily:  return quest.isCommitted
            case .oneOff: return quest.isFreeform
            case .goal:   return quest.isGoal
            }
        }
        let sorted = subset.sorted { a, b in
            let ad = a.displayAsCompleted(referenceDate: ref)
            let bd = b.displayAsCompleted(referenceDate: ref)
            if ad != bd { return !ad && bd }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
        // Skip the assignment if nothing changed to avoid triggering a list re-render.
        guard sorted.map(\.id) != visibleQuests.map(\.id) else { return }
        visibleQuests = sorted
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
            checkDifficultyPromptIfNeeded()
        case .tierBlockedInLockdown:
            onPresentLockdownTierBlockedAlert?()
        case .notEligible:
            break
        }
    }

    // MARK: - Difficulty check

    private func checkDifficultyPromptIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "hasSeenDifficultyCheck") else { return }
        let count = defaults.integer(forKey: "totalQuestCompletions") + 1
        defaults.set(count, forKey: "totalQuestCompletions")
        if count >= 3 {
            defaults.set(true, forKey: "hasSeenDifficultyCheck")
            onShouldShowDifficultyCheck?()
        }
    }
}
