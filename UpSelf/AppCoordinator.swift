//
//  AppCoordinator.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//

import SwiftData
import SwiftUI
import UIKit

class AppCoordinator: NSObject, UINavigationControllerDelegate, UITabBarControllerDelegate {

    let tabBarController: UITabBarController
    /// Home tab: dashboard, pushes, and sheets.
    let navigationController: UINavigationController

    private let settingsNavigationController: UINavigationController
    private let modelContainer: ModelContainer

    private var dashboardViewModel: DashboardViewModel?
    private weak var createQuestHostingController: UIViewController?
    private var didStart = false

    /// Serializes `UIAlertController` work to avoid overlapping `present` with sheets, tabs, or other alerts.
    private var globalAlertQueue: [(@escaping () -> Void) -> Void] = []
    private var isProcessingGlobalAlertQueue = false

    init(modelContainer: ModelContainer) {
        let homeNav = UINavigationController()
        let settingsNav = UINavigationController()
        let tabs = UITabBarController()

        self.navigationController = homeNav
        self.settingsNavigationController = settingsNav
        self.tabBarController = tabs
        self.modelContainer = modelContainer

        super.init()

        homeNav.delegate = self

        homeNav.tabBarItem = UITabBarItem(
            title: String(localized: L10n.Settings.tabHome),
            image: UIImage(systemName: "house.fill"),
            tag: 0
        )
        settingsNav.tabBarItem = UITabBarItem(
            title: String(localized: L10n.Settings.tabSettings),
            image: UIImage(systemName: "gearshape.fill"),
            tag: 1
        )

        tabs.viewControllers = [homeNav, settingsNav]
        tabs.tabBar.tintColor = UIColor(AppTheme.Colors.accentXP)

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(AppTheme.Colors.card)
        tabs.tabBar.standardAppearance = tabAppearance
        tabs.tabBar.scrollEdgeAppearance = tabAppearance

        tabs.delegate = self
    }

    func start() {
        guard !didStart else { return }
        didStart = true

        let clock = DependencyContainer[\.gameClock]

        let viewModel = DashboardViewModel()
        dashboardViewModel = viewModel
        viewModel.onPresentCreateQuest = { [weak self] in
            self?.presentCreateQuest()
        }
        viewModel.onPresentHistoryLog = { [weak self] in
            self?.pushHistoryLog()
        }
        viewModel.onPresentQuestLog = { [weak self] in
            self?.pushQuestLog()
        }
        viewModel.onPushRecoveryQuestList = { [weak self] in
            self?.pushRecoveryQuestList()
        }

        let dashboardRoot = DashboardView(viewModel: viewModel)
            .modelContainer(modelContainer)
            .environment(\.gameClock, clock)
        let initialVC = UIHostingController(rootView: dashboardRoot)
        initialVC.view.backgroundColor = AppTheme.UIKitColors.background

        navigationController.setViewControllers([initialVC], animated: false)

        let settingsRoot = SettingsView()
            .modelContainer(modelContainer)
            .environment(\.gameClock, clock)
        let settingsHosting = UIHostingController(rootView: settingsRoot)
        settingsHosting.view.backgroundColor = AppTheme.UIKitColors.background

        settingsNavigationController.setViewControllers([settingsHosting], animated: false)
    }

    func presentCreateQuest() {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        do {
            if let profile = try modelContainer.mainContext.fetch(descriptor).first,
               !LockdownPolicy.allows(.createQuest, isInLockdown: profile.isInLockdown) {
                presentLockdownBlocksCreateQuestAlert()
                return
            }
        } catch {
            assertionFailure("presentCreateQuest profile fetch: \(error)")
        }

        let viewModel = CreateQuestViewModel(modelContext: modelContainer.mainContext) { [weak self] in
            self?.dismissCreateQuestIfPresented()
        }

        let sheetConfig = ContentSizedSheet.Configuration(
            extraChromeHeight: 36,
            minimumDetentHeight: 380,
            initialDetentHeight: 440
        )
        let sheetDetentBridge = ContentSizedSheet.UIKitDetentBridge(configuration: sheetConfig)

        let root = CreateQuestView(viewModel: viewModel)
            .modelContainer(modelContainer)
            .environment(\.contentSizedSheetUIKitDetentBridge, sheetDetentBridge)

        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = AppTheme.UIKitColors.background
        hosting.modalPresentationStyle = .pageSheet

        sheetDetentBridge.onInvalidateDetents = { [weak hosting] in
            hosting?.sheetPresentationController?.invalidateDetents()
        }

        if let sheet = hosting.sheetPresentationController {
            let detentIdentifier = UISheetPresentationController.Detent.Identifier("upself.create_quest.content")
            let contentDetent = UISheetPresentationController.Detent.custom(identifier: detentIdentifier) { [weak sheetDetentBridge] context in
                guard let sheetDetentBridge else {
                    return min(sheetConfig.initialDetentHeight, context.maximumDetentValue)
                }
                return sheetDetentBridge.resolvedDetentHeight(maximumDetent: context.maximumDetentValue)
            }
            sheet.detents = [contentDetent]
            sheet.selectedDetentIdentifier = detentIdentifier
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        createQuestHostingController = hosting
        navigationController.present(hosting, animated: true)
    }

    func pushHistoryLog() {
        let root = HistoryLogView()
            .modelContainer(modelContainer)
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = AppTheme.UIKitColors.background
        hosting.navigationItem.title = String(localized: L10n.HistoryLog.title)
        hosting.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hosting, animated: true)
    }

    func pushQuestLog() {
        let clock = DependencyContainer[\.gameClock]
        let viewModel = QuestLogViewModel(modelContext: modelContainer.mainContext, gameClock: clock)
        // Defer pop: synchronous navigation from SwiftUI `onAppear` / `onChange` can tear down
        // `UIHostingController` mid–update-cycle and cause intermittent crashes with Observation/@Query.
        viewModel.onLockdownEngagedExit = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                guard self.navigationController.viewControllers.count > 1 else { return }
                self.navigationController.popViewController(animated: true)
            }
        }
        let root = QuestLogView(viewModel: viewModel)
            .modelContainer(modelContainer)
            .environment(\.gameClock, clock)
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = AppTheme.UIKitColors.background
        hosting.navigationItem.title = String(localized: L10n.QuestLog.title)
        hosting.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hosting, animated: true)
    }

    func pushRecoveryQuestList() {
        let clock = DependencyContainer[\.gameClock]
        let viewModel = QuestLogViewModel(modelContext: modelContainer.mainContext, gameClock: clock)
        viewModel.onLockdownClearedExit = { [weak self] in
            self?.popRecoveryQuestListAndPresentExitSuccess()
        }
        let root = RecoveryQuestListView(viewModel: viewModel)
            .modelContainer(modelContainer)
            .environment(\.gameClock, clock)
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = AppTheme.UIKitColors.background
        hosting.navigationItem.title = String(localized: L10n.Lockdown.recoverySheetTitle)
        hosting.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hosting, animated: true)
    }

    private func popRecoveryQuestListAndPresentExitSuccess() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard self.navigationController.viewControllers.count > 1 else { return }
            self.navigationController.popViewController(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.presentLockdownExitSuccessAlert()
            }
        }
    }

    private func presentLockdownExitSuccessAlert() {
        let title = String(localized: L10n.Lockdown.exitSuccessTitle)
        let message = String(localized: L10n.Lockdown.exitSuccessMessage)
        let acceptTitle = String(localized: L10n.Common.ok)
        enqueueGlobalAlert { [weak self] finish in
            guard let self else {
                finish()
                return
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: acceptTitle, style: .default) { _ in
                finish()
            })
            self.presentOnIdleAlertHost(alert, animated: true, ifUnableToPresent: finish)
        }
    }

    private func presentLockdownBlocksCreateQuestAlert() {
        let title = String(localized: L10n.Lockdown.createQuestBlockedTitle)
        let message = String(localized: L10n.Lockdown.createQuestBlockedBody)
        let acceptTitle = String(localized: L10n.Common.ok)
        enqueueGlobalAlert { [weak self] finish in
            guard let self else {
                finish()
                return
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: acceptTitle, style: .default) { _ in
                finish()
            })
            self.presentOnIdleAlertHost(alert, animated: true, ifUnableToPresent: finish)
        }
    }

    private func dismissCreateQuestIfPresented() {
        guard let hosting = createQuestHostingController else { return }
        hosting.dismiss(animated: true) { [weak self] in
            self?.createQuestHostingController = nil
        }
    }

    /// Presents a system alert above any pushed screen or modal (`UIAlertController` on the topmost VC).
    func presentMissedDailyHPLossAlert(totalHPLost: Int) {
        guard totalHPLost > 0 else { return }
        let title = String(localized: L10n.HUD.hpLossAlertTitle)
        let message = L10n.HUD.hpLossAlertMessage(totalLost: totalHPLost)
        let acceptTitle = String(localized: L10n.HUD.hpLossAlertAccept)
        enqueueGlobalAlert { [weak self] finish in
            guard let self else {
                finish()
                return
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: acceptTitle, style: .default) { [weak self] _ in
                self?.navigateToDashboardForHPLossReview()
                DispatchQueue.main.async {
                    finish()
                }
            })
            self.presentOnIdleAlertHost(alert, animated: true, ifUnableToPresent: finish)
        }
    }

    /// Home tab, dashboard root; dismisses a presented sheet on the home stack if needed so the HUD is visible.
    func navigateToDashboardForHPLossReview() {
        tabBarController.selectedIndex = 0
        if let presented = navigationController.presentedViewController {
            presented.dismiss(animated: true) { [weak self] in
                if presented === self?.createQuestHostingController {
                    self?.createQuestHostingController = nil
                }
                DispatchQueue.main.async {
                    _ = self?.navigationController.popToRootViewController(animated: true)
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                _ = self?.navigationController.popToRootViewController(animated: true)
            }
        }
    }

    private static func topMostViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topMostViewController(from: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return topMostViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(from: selected)
        }
        return root
    }

    // MARK: - Global alert queue

    /// One alert at a time; `builder` receives `finish`, which **must** run when the alert path is done (including button taps).
    private func enqueueGlobalAlert(_ builder: @escaping (@escaping () -> Void) -> Void) {
        globalAlertQueue.append(builder)
        processGlobalAlertQueueIfNeeded()
    }

    private func processGlobalAlertQueueIfNeeded() {
        guard !isProcessingGlobalAlertQueue, !globalAlertQueue.isEmpty else { return }
        isProcessingGlobalAlertQueue = true
        let next = globalAlertQueue.removeFirst()
        DispatchQueue.main.async { [weak self] in
            next {
                self?.completeGlobalAlertQueueItem()
            }
        }
    }

    private func completeGlobalAlertQueueItem() {
        isProcessingGlobalAlertQueue = false
        processGlobalAlertQueueIfNeeded()
    }

    /// Presents when the top VC is not mid-transition; retries on the next run loop if needed.
    private func presentOnIdleAlertHost(_ alert: UIAlertController, animated: Bool, ifUnableToPresent: @escaping () -> Void, idleRetryAttempt: Int = 0) {
        let host = Self.topMostViewController(from: tabBarController)
        if host.isBeingDismissed || host.isMovingToParent || host.isBeingPresented {
            if idleRetryAttempt >= 24 {
                ifUnableToPresent()
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.presentOnIdleAlertHost(alert, animated: animated, ifUnableToPresent: ifUnableToPresent, idleRetryAttempt: idleRetryAttempt + 1)
            }
            return
        }
        host.present(alert, animated: animated) {
            if host.presentedViewController !== alert {
                ifUnableToPresent()
            }
        }
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard navigationController === self.navigationController else { return }
        let isDashboardRoot = navigationController.viewControllers.first === viewController
        navigationController.setNavigationBarHidden(isDashboardRoot, animated: animated)
    }

    // MARK: - UITabBarControllerDelegate

    /// When opening **Settings**, pop the **home** stack so a pushed screen (e.g. activity log) isn’t left
    /// under an inactive tab. Do **not** pop the settings stack when returning home — doing that during the
    /// tab transition races with `UIHostingController` + SwiftUI (`@Observable` / game clock) and can crash.
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard viewController === settingsNavigationController else { return }
        guard navigationController.viewControllers.count > 1 else { return }
        let popHomeToRoot = { [weak self] in
            _ = self?.navigationController.popToRootViewController(animated: false)
        }
        if let coordinator = tabBarController.transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] context in
                guard let self else { return }
                guard !context.isCancelled else { return }
                popHomeToRoot()
            }
        } else {
            DispatchQueue.main.async(execute: popHomeToRoot)
        }
    }
}

struct CoordinatorView: UIViewControllerRepresentable {
    let coordinator: AppCoordinator

    func makeUIViewController(context: Context) -> UITabBarController {
        /// `start()` is idempotent (`didStart`); avoids rebuilding stacks if representable is recreated.
        coordinator.start()
        return coordinator.tabBarController
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}
