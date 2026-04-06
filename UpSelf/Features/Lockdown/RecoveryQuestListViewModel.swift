//
//  RecoveryQuestListViewModel.swift
//  UpSelf
//
//  Presentation logic for the lockdown recovery quest list; routing stays in AppCoordinator.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class RecoveryQuestListViewModel {

    private let modelContext: ModelContext
    private let completionService: QuestCompletionServiceProtocol

    /// Pop the nav stack and present the exit-success alert when lockdown clears.
    var onLockdownClearedExit: (() -> Void)?

    /// System alert when the user swipes a tier that is still blocked in lockdown.
    var onPresentLockdownTierBlockedAlert: (() -> Void)?

    /// Confirm before completing a recovery quest (AppCoordinator shows the alert).
    var onPresentRecoveryQuestCompleteConfirm: ((_ questTitle: String, _ onConfirmed: @escaping () -> Void) -> Void)?

    // MARK: - Display state (populated by refresh)

    var epicQuests: [Quest] = []
    var hardQuests: [Quest] = []

    var hasAnyQuest: Bool { !epicQuests.isEmpty || !hardQuests.isEmpty }

    init(
        modelContext: ModelContext,
        completionService: QuestCompletionServiceProtocol = DependencyContainer[\.questCompletionService]
    ) {
        self.modelContext = modelContext
        self.completionService = completionService
    }

    // MARK: - Data refresh

    func refresh(allQuests: [Quest], profiles: [UserProfile], clock: GameClock) {
        guard let profile = profiles.first else {
            epicQuests = []
            hardQuests = []
            return
        }
        let id = profile.id
        let ref = clock.now
        let episodeStart = profile.lockdownEpisodeStart

        epicQuests = sorted(allQuests.filter { $0.user?.id == id && $0.rewardTier == .epic },
                            ref: ref, episodeStart: episodeStart)
        hardQuests = sorted(allQuests.filter { $0.user?.id == id && $0.rewardTier == .hard },
                            ref: ref, episodeStart: episodeStart)
    }

    private func sorted(_ quests: [Quest], ref: Date, episodeStart: Date?) -> [Quest] {
        quests.sorted { a, b in
            let ad = a.recoveryListDisplayCompleted(referenceDate: ref, lockdownEpisodeStart: episodeStart)
            let bd = b.recoveryListDisplayCompleted(referenceDate: ref, lockdownEpisodeStart: episodeStart)
            if ad != bd { return !ad && bd }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    // MARK: - Row state

    func isTierBlockedInLockdown(_ quest: Quest, profile: UserProfile?) -> Bool {
        guard let profile, profile.isInLockdown, let tier = quest.rewardTier else { return false }
        return !LockdownPolicy.allows(.completeQuest(tier: tier), isInLockdown: true)
    }

    // MARK: - Actions

    func completePersistedQuest(_ quest: Quest) {
        guard let result = try? completionService.complete(quest, context: modelContext) else { return }
        switch result {
        case .completed:
            break
        case .completedAndClearedLockdown:
            onLockdownClearedExit?()
        case .tierBlockedInLockdown:
            onPresentLockdownTierBlockedAlert?()
        case .notEligible:
            break
        }
    }

    func presentRecoveryQuestCompleteConfirm(questTitle: String, onConfirmed: @escaping () -> Void) {
        onPresentRecoveryQuestCompleteConfirm?(questTitle, onConfirmed)
    }
}
