//
//  AppRootView.swift
//  UpSelf
//
//  SwiftUI root: TabView + NavigationStack. Replaces CoordinatorView + AppCoordinator.
//  All navigation state lives in AppNavigator (injected via @Environment).
//

import SwiftData
import SwiftUI

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @Environment(AppNavigator.self) private var navigator
    @Environment(\.gameClock) private var gameClock

    // ViewModels that must survive tab switches are held here as @State.
    @State private var dashboardViewModel = DashboardViewModel()
    @State private var settingsViewModel: SettingsViewModel?

    private var modelContainer: ModelContainer { DependencyContainer[\.modelContainer] }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { navigator.pendingAlert != nil },
            set: { isPresented in if !isPresented { navigator.alertDismissed() } }
        )
    }

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingContainerView(modelContext: modelContainer.mainContext)
        } else {
            mainApp
        }
    }

    @ViewBuilder
    private var mainApp: some View {
        @Bindable var nav = navigator

        TabView(selection: $nav.selectedTab) {
            homeTab
                .tabItem {
                    Label(String(localized: L10n.Settings.tabHome), systemImage: "house.fill")
                }
                .tag(0)

            settingsTab
                .tabItem {
                    Label(String(localized: L10n.Settings.tabSettings), systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(AppTheme.Colors.accentXP)
        .alert(
            navigator.pendingAlert?.alertTitle ?? "",
            isPresented: alertBinding,
            presenting: navigator.pendingAlert
        ) { alert in
            alertActions(for: alert)
        } message: { alert in
            Text(alert.alertMessage)
        }
        .onChange(of: nav.selectedTab) { _, newTab in
            // When user switches to Settings, pop home stack so a pushed screen
            // (e.g. quest log) is not left orphaned under an inactive tab.
            if newTab == 1 {
                navigator.popHomeToRoot()
            }
        }
        .onAppear {
            wireDashboardViewModel()
            wireSettingsViewModel()
        }
        .sheet(isPresented: Bindable(navigator).showDifficultyCheck) {
            DifficultyCheckView(
                modelContext: modelContainer.mainContext,
                onDismiss: { navigator.showDifficultyCheck = false }
            )
        }
    }

    // MARK: - Tabs

    private var homeTab: some View {
        NavigationStack(path: Bindable(navigator).homePath) {
            DashboardView(viewModel: dashboardViewModel)
                .navigationBarHidden(true)
                .navigationDestination(for: HomeDestination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .sheet(isPresented: Bindable(navigator).isCreateQuestPresented) {
            createQuestSheet
        }
    }

    private var settingsTab: some View {
        NavigationStack {
            Group {
                if let vm = settingsViewModel {
                    SettingsView(viewModel: vm)
                }
            }
        }
    }

    // MARK: - Destination routing

    @ViewBuilder
    private func destinationView(for destination: HomeDestination) -> some View {
        switch destination {
        case .historyLog:
            HistoryLogView()
                .navigationTitle(String(localized: L10n.HistoryLog.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)

        case .questLog:
            let vm = makeQuestLogViewModel()
            QuestLogView(viewModel: vm)
                .navigationTitle(String(localized: L10n.QuestLog.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)

        case .recoveryQuestList:
            let vm = makeRecoveryQuestListViewModel()
            RecoveryQuestListView(viewModel: vm)
                .navigationTitle(String(localized: L10n.Lockdown.recoverySheetTitle))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)
        }
    }

    // MARK: - Create Quest sheet

    private var createQuestSheet: some View {
        let vm = CreateQuestViewModel(
            modelContext: modelContainer.mainContext,
            onDismiss: { navigator.dismissCreateQuest() }
        )
        return CreateQuestView(viewModel: vm)
            .contentSizedSheetPresentation(ContentSizedSheet.Configuration(
                extraChromeHeight: 36,
                minimumDetentHeight: 380,
                initialDetentHeight: 440
            ))
    }

    // MARK: - ViewModel wiring

    private func wireDashboardViewModel() {
        dashboardViewModel.onPresentCreateQuest = { [weak navigator] in
            navigator?.presentCreateQuest(modelContainer: DependencyContainer[\.modelContainer])
        }
        dashboardViewModel.onPresentHistoryLog = { [weak navigator] in
            navigator?.pushHome(.historyLog)
        }
        dashboardViewModel.onPresentQuestLog = { [weak navigator] in
            navigator?.pushHome(.questLog)
        }
        dashboardViewModel.onPushRecoveryQuestList = { [weak navigator] in
            navigator?.pushHome(.recoveryQuestList)
        }
        dashboardViewModel.onPresentLockdownRecoveryInfo = { [weak navigator] minHard, minEpic in
            navigator?.enqueueAlert(.lockdownRecoveryInfo(minHard: minHard, minEpic: minEpic))
        }
    }

    private func wireSettingsViewModel() {
        guard settingsViewModel == nil else { return }
        let vm = SettingsViewModel(
            modelContext: modelContainer.mainContext,
            gameClock: gameClock
        )
        vm.onRequestLocalDataResetConfirmation = { [weak vm, weak navigator] in
            guard let vm else { return }
            navigator?.enqueueAlert(.localDataResetConfirm { vm.performLocalDataReset() })
        }
        settingsViewModel = vm
    }

    private func makeQuestLogViewModel() -> QuestLogViewModel {
        let vm = QuestLogViewModel(
            modelContext: modelContainer.mainContext,
            gameClock: gameClock
        )
        vm.onLockdownEngagedExit = { [weak navigator] in
            navigator?.popHome()
        }
        vm.onPresentLockdownTierBlockedAlert = { [weak navigator] in
            navigator?.enqueueAlert(.lockdownTierBlocked)
        }
        vm.onPresentQuestLogInstructions = { [weak navigator] in
            navigator?.enqueueAlert(.questLogInstructions)
        }
        vm.onShouldShowDifficultyCheck = { [weak navigator] in
            navigator?.showDifficultyCheck = true
        }
        return vm
    }

    private func makeRecoveryQuestListViewModel() -> RecoveryQuestListViewModel {
        let vm = RecoveryQuestListViewModel(modelContext: modelContainer.mainContext)
        vm.onLockdownClearedExit = { [weak navigator] in
            navigator?.popHome()
            navigator?.enqueueAlert(.lockdownExitSuccess)
        }
        vm.onPresentLockdownTierBlockedAlert = { [weak navigator] in
            navigator?.enqueueAlert(.lockdownTierBlocked)
        }
        vm.onPresentRecoveryQuestCompleteConfirm = { [weak navigator] questTitle, onConfirmed in
            navigator?.enqueueAlert(.recoveryQuestCompleteConfirm(
                questTitle: questTitle,
                onConfirmed: onConfirmed
            ))
        }
        return vm
    }

    // MARK: - Alert actions builder

    @ViewBuilder
    private func alertActions(for alert: AppAlert) -> some View {
        switch alert {
        case .missedDailyHPLoss(_, let onDismiss):
            Button(String(localized: L10n.HUD.hpLossAlertAccept)) {
                navigator.switchToHomeAndPopToRoot()
                onDismiss()
            }
        case .lockdownCreateQuestBlocked, .lockdownTierBlocked,
             .questLogInstructions, .lockdownRecoveryInfo, .lockdownExitSuccess:
            Button(String(localized: L10n.Common.ok)) { }
        case .recoveryQuestCompleteConfirm(_, let onConfirmed):
            Button(String(localized: L10n.Lockdown.recoveryCompleteConfirmAction)) { onConfirmed() }
            Button(String(localized: L10n.Common.cancel), role: .cancel) { }
        case .localDataResetConfirm(let onConfirmed):
            Button(String(localized: L10n.Settings.dataResetConfirm), role: .destructive) { onConfirmed() }
            Button(String(localized: L10n.Common.cancel), role: .cancel) { }
        }
    }
}
