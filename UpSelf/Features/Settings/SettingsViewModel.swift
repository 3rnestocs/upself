//
//  SettingsViewModel.swift
//  UpSelf
//
//  Presentation and mutations for Settings; SwiftData writes stay off the View.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {

    private let modelContext: ModelContext
    private let gameClock: GameClock
    private let resetService: LocalAppResetServiceProtocol

    /// Shown when persisting lockdown minimums fails (replaces silent `try? save()`).
    var lockdownPersistenceError: String?

    var resetDataStatus: String?

    #if DEBUG
    var developerWatermarkStatus: String?
    /// Draft calendar offset; Apply writes to `gameClock`.
    var draftDayOffset: Int = 0
    #endif

    /// Set by `AppRootView` to enqueue a confirmation alert via `AppNavigator`.
    var onRequestLocalDataResetConfirmation: (() -> Void)?

    init(
        modelContext: ModelContext,
        gameClock: GameClock,
        resetService: LocalAppResetServiceProtocol = DependencyContainer[\.localAppResetService]
    ) {
        self.modelContext = modelContext
        self.gameClock = gameClock
        self.resetService = resetService
    }

    func onAppear() {
        #if DEBUG
        draftDayOffset = gameClock.dayOffset
        #endif
    }

    var hasUnappliedGameDayDraft: Bool {
        #if DEBUG
        draftDayOffset != gameClock.dayOffset
        #else
        false
        #endif
    }

    #if DEBUG
    func formattedDraftGameDayLabel() -> String {
        gameClock.formattedGameCalendarDayLabel(dayOffset: draftDayOffset)
    }

    func applyGameDayDraft() {
        gameClock.dayOffset = draftDayOffset
    }

    func useRealGameDay() {
        draftDayOffset = 0
        gameClock.dayOffset = 0
    }

    func debugResetMissedDailyWatermark() {
        do {
            try MissedDailyPenaltyService.debugResetEvaluationWatermark(
                context: modelContext,
                clock: gameClock
            )
            developerWatermarkStatus = String(localized: L10n.Settings.watermarkResetDone)
        } catch {
            developerWatermarkStatus = String(localized: L10n.Settings.watermarkResetFailed)
        }
    }
    #endif

    func updateLockdownMinEpic(for profile: UserProfile, rawValue: Int) {
        let clamped = max(0, min(20, rawValue))
        let previousEpic = profile.lockdownMinEpicQuestsToClear
        let previousHard = profile.lockdownMinHardQuestsToClear
        profile.lockdownMinEpicQuestsToClear = clamped
        Self.normalizeLockdownMinimums(profile)
        persistAfterLockdownChange(revertingOnFailure: profile, epic: previousEpic, hard: previousHard)
    }

    func updateLockdownMinHard(for profile: UserProfile, rawValue: Int) {
        let clamped = max(0, min(20, rawValue))
        let previousEpic = profile.lockdownMinEpicQuestsToClear
        let previousHard = profile.lockdownMinHardQuestsToClear
        profile.lockdownMinHardQuestsToClear = clamped
        Self.normalizeLockdownMinimums(profile)
        persistAfterLockdownChange(revertingOnFailure: profile, epic: previousEpic, hard: previousHard)
    }

    func requestLocalDataResetConfirmation() {
        onRequestLocalDataResetConfirmation?()
    }

    func performLocalDataReset() {
        do {
            try resetService.resetAllLocalState(context: modelContext)
            resetDataStatus = String(localized: L10n.Settings.dataResetDone)
            lockdownPersistenceError = nil
            #if DEBUG
            draftDayOffset = gameClock.dayOffset
            #endif
        } catch {
            resetDataStatus = String(localized: L10n.Settings.dataResetFailed)
        }
    }

    private func persistAfterLockdownChange(revertingOnFailure profile: UserProfile, epic: Int, hard: Int) {
        do {
            try modelContext.save()
            lockdownPersistenceError = nil
        } catch {
            profile.lockdownMinEpicQuestsToClear = epic
            profile.lockdownMinHardQuestsToClear = hard
            lockdownPersistenceError = String(localized: L10n.Settings.lockdownSaveFailed)
        }
    }

    private static func normalizeLockdownMinimums(_ profile: UserProfile) {
        if profile.lockdownMinEpicQuestsToClear == 0 && profile.lockdownMinHardQuestsToClear == 0 {
            profile.lockdownMinEpicQuestsToClear = 1
            profile.lockdownMinHardQuestsToClear = 2
        }
    }
}
