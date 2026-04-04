//
//  DashboardViewModel.swift
//  UpSelf
//
//  Presentation logic for the HUD; routing stays in AppCoordinator.
//

import Foundation

@MainActor
@Observable
final class DashboardViewModel {

    /// Set by `AppCoordinator` to present the create-quest sheet.
    var onPresentCreateQuest: (() -> Void)?

    /// Set by `AppCoordinator` to push the activity log screen.
    var onPresentHistoryLog: (() -> Void)?

    /// Set by `AppCoordinator` to push the quest log screen.
    var onPresentQuestLog: (() -> Void)?

    /// Set by `AppCoordinator` to push the lockdown recovery (hard/epic) list.
    var onPushRecoveryQuestList: (() -> Void)?

    /// Set by `AppCoordinator` to show lockdown recovery requirements (system alert).
    var onPresentLockdownRecoveryInfo: ((_ minHard: Int, _ minEpic: Int) -> Void)?

    init() {}

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
