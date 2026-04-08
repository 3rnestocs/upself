//
//  AppNavigator.swift
//  UpSelf
//
//  Observable navigation state for the whole app. Replaces AppCoordinator.
//  Views and ViewModels never navigate directly — they call methods here.
//

import SwiftData
import SwiftUI

// MARK: - HomeDestination

/// Destinations pushable onto the home NavigationStack.
enum HomeDestination: Hashable {
    case questLog
    case recoveryQuestList
    case historyLog
}

// MARK: - AppAlert

/// Alert payloads — one case per distinct alert the app can show.
/// Uses `Identifiable` so SwiftUI's `alert(item:)` drives presentation automatically.
enum AppAlert: Identifiable {
    case missedDailyHPLoss(totalHPLost: Int, onDismiss: () -> Void)
    case lockdownCreateQuestBlocked
    case lockdownTierBlocked
    case questLogInstructions
    case lockdownRecoveryInfo(minHard: Int, minEpic: Int)
    case lockdownExitSuccess
    case recoveryQuestCompleteConfirm(questTitle: String, onConfirmed: () -> Void)
    case localDataResetConfirm(onConfirmed: () -> Void)

    var id: String {
        switch self {
        case .missedDailyHPLoss:              return "missedDailyHPLoss"
        case .lockdownCreateQuestBlocked:     return "lockdownCreateQuestBlocked"
        case .lockdownTierBlocked:            return "lockdownTierBlocked"
        case .questLogInstructions:           return "questLogInstructions"
        case .lockdownRecoveryInfo:           return "lockdownRecoveryInfo"
        case .lockdownExitSuccess:            return "lockdownExitSuccess"
        case .recoveryQuestCompleteConfirm:   return "recoveryQuestCompleteConfirm"
        case .localDataResetConfirm:          return "localDataResetConfirm"
        }
    }

    var alertTitle: String {
        switch self {
        case .missedDailyHPLoss:              return String(localized: L10n.HUD.hpLossAlertTitle)
        case .lockdownCreateQuestBlocked:     return String(localized: L10n.Lockdown.createQuestBlockedTitle)
        case .lockdownTierBlocked:            return String(localized: L10n.Lockdown.cannotCompleteEasyRegularTitle)
        case .questLogInstructions:           return String(localized: L10n.QuestLog.instructionsTitle)
        case .lockdownRecoveryInfo:           return String(localized: L10n.Lockdown.recoveryInfoAlertTitle)
        case .lockdownExitSuccess:            return String(localized: L10n.Lockdown.exitSuccessTitle)
        case .recoveryQuestCompleteConfirm:   return String(localized: L10n.Lockdown.recoveryCompleteConfirmTitle)
        case .localDataResetConfirm:          return String(localized: L10n.Settings.dataResetAlertTitle)
        }
    }

    var alertMessage: String {
        switch self {
        case .missedDailyHPLoss(let total, _):          return L10n.HUD.hpLossAlertMessage(totalLost: total)
        case .lockdownCreateQuestBlocked:               return String(localized: L10n.Lockdown.createQuestBlockedBody)
        case .lockdownTierBlocked:                      return String(localized: L10n.Lockdown.cannotCompleteEasyRegularBody)
        case .questLogInstructions:                     return String(localized: L10n.QuestLog.instructionsBody)
        case .lockdownRecoveryInfo(let minHard, let minEpic): return L10n.Lockdown.recoveryInfoAlertMessage(minHard: minHard, minEpic: minEpic)
        case .lockdownExitSuccess:                      return String(localized: L10n.Lockdown.exitSuccessMessage)
        case .recoveryQuestCompleteConfirm(let title, _): return L10n.Lockdown.recoveryCompleteConfirmMessage(questTitle: title)
        case .localDataResetConfirm:                    return String(localized: L10n.Settings.dataResetAlertMessage)
        }
    }
}

// MARK: - AppNavigator

@MainActor
@Observable
final class AppNavigator {

    // MARK: - Tab selection

    var selectedTab: Int = 0

    // MARK: - Home stack

    var homePath = NavigationPath()

    // MARK: - Sheet

    var isCreateQuestPresented: Bool = false
    var showDifficultyCheck: Bool = false

    // MARK: - Alert queue

    /// The currently displayed alert. `AppRootView` drives `.alert(item:)` from this.
    var pendingAlert: AppAlert? = nil
    private var alertQueue: [AppAlert] = []

    // MARK: - Navigation

    func pushHome(_ destination: HomeDestination) {
        selectedTab = 0
        homePath.append(destination)
    }

    func popHome() {
        guard !homePath.isEmpty else { return }
        homePath.removeLast()
    }

    func popHomeToRoot() {
        homePath = NavigationPath()
    }

    /// Checks lockdown policy before presenting; enqueues an alert if blocked.
    func presentCreateQuest(modelContainer: ModelContainer) {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        do {
            if let profile = try modelContainer.mainContext.fetch(descriptor).first,
               !LockdownPolicy.allows(.createQuest, isInLockdown: profile.isInLockdown) {
                enqueueAlert(.lockdownCreateQuestBlocked)
                return
            }
        } catch {
            assertionFailure("presentCreateQuest profile fetch: \(error)")
        }
        selectedTab = 0
        isCreateQuestPresented = true
    }

    func dismissCreateQuest() {
        isCreateQuestPresented = false
    }

    func switchToHomeAndPopToRoot() {
        selectedTab = 0
        popHomeToRoot()
    }

    // MARK: - Alert queue

    func enqueueAlert(_ alert: AppAlert) {
        guard alertQueue.allSatisfy({ $0.id != alert.id }),
              pendingAlert?.id != alert.id else { return }
        alertQueue.append(alert)
        drainAlertQueueIfNeeded()
    }

    func alertDismissed() {
        pendingAlert = nil
        drainAlertQueueIfNeeded()
    }

    private func drainAlertQueueIfNeeded() {
        guard pendingAlert == nil, !alertQueue.isEmpty else { return }
        pendingAlert = alertQueue.removeFirst()
    }
}
