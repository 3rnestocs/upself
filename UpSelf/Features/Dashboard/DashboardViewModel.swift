//
//  DashboardViewModel.swift
//  UpSelf
//
//  Presentation logic for the HUD; routing stays in AppNavigator (wired by AppRootView).
//

import Foundation

@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - Navigation callbacks (set by AppRootView via AppNavigator)

    var onPresentCreateQuest: (() -> Void)?
    var onPresentHistoryLog: (() -> Void)?
    var onPresentQuestLog: (() -> Void)?
    var onPushRecoveryQuestList: (() -> Void)?
    var onPresentLockdownRecoveryInfo: ((_ minHard: Int, _ minEpic: Int) -> Void)?

    // MARK: - Display state (populated by refresh)

    var displayStats: [CharacterStat] = []
    var dailyQuests: [Quest] = []
    var completedDailiesToday: Int = 0
    var hasOneOffQuestsOnly: Bool = false
    var hasAnyQuests: Bool = false
    var currentHP: Int = 0
    var maxHP: Int = 100
    var isInLockdown: Bool = false
    var lockdownMinHardQuestsToClear: Int = 0
    var lockdownMinEpicQuestsToClear: Int = 0
    var createQuestAllowed: Bool = true
    var dailyBriefNavAllowed: Bool = true

    init() {}

    // MARK: - Data refresh

    /// Called from the View's onAppear and onChange(of:) for each @Query array.
    func refresh(profiles: [UserProfile], stats: [CharacterStat], quests: [Quest], clock: GameClock) {
        guard let profile = profiles.first else {
            displayStats = []
            dailyQuests = []
            completedDailiesToday = 0
            hasOneOffQuestsOnly = false
            hasAnyQuests = false
            return
        }
        let id = profile.id
        let ref = clock.now

        displayStats = stats
            .filter { $0.user?.id == id }
            .sorted { a, b in
                let ia = CharacterAttribute.allCases.firstIndex { $0.rawValue == a.kindRawValue } ?? Int.max
                let ib = CharacterAttribute.allCases.firstIndex { $0.rawValue == b.kindRawValue } ?? Int.max
                return ia < ib
            }

        let userQuests = quests.filter { $0.user?.id == id }
        let dailies = userQuests
            .filter(\.isDaily)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        dailyQuests = dailies
        completedDailiesToday = dailies.filter { $0.displayAsCompleted(referenceDate: ref) }.count
        hasOneOffQuestsOnly = dailies.isEmpty && userQuests.contains { !$0.isDaily }
        hasAnyQuests = !userQuests.isEmpty

        currentHP = profile.currentHP
        maxHP = profile.maxHP
        isInLockdown = profile.isInLockdown
        lockdownMinHardQuestsToClear = profile.lockdownMinHardQuestsToClear
        lockdownMinEpicQuestsToClear = profile.lockdownMinEpicQuestsToClear

        createQuestAllowed = LockdownPolicy.allows(.createQuest, isInLockdown: profile.isInLockdown)
        dailyBriefNavAllowed = LockdownPolicy.allows(.dailyBrief, isInLockdown: profile.isInLockdown)
    }

    // MARK: - Actions

    func presentCreateQuest() {
        onPresentCreateQuest?()
    }

    func presentHistoryLog() {
        onPresentHistoryLog?()
    }

    func presentQuestLog() {
        onPresentQuestLog?()
    }

    func pushRecoveryQuestList() {
        onPushRecoveryQuestList?()
    }

    func presentLockdownRecoveryInfo(minHard: Int, minEpic: Int) {
        onPresentLockdownRecoveryInfo?(minHard, minEpic)
    }
}
