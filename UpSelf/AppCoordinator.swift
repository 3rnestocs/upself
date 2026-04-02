//
//  AppCoordinator.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//

import SwiftData
import SwiftUI
import UIKit

class AppCoordinator {
    let navigationController: UINavigationController
    private let modelContainer: ModelContainer
    private let screenTimeService: ScreenTimeServiceProtocol

    private var dashboardViewModel: DashboardViewModel?
    private weak var questCompletionHostingController: UIViewController?
    #if os(iOS) || os(visionOS)
    private weak var lockdownHostingController: UIViewController?
    #endif

    init(
        navigationController: UINavigationController = UINavigationController(),
        modelContainer: ModelContainer,
        screenTimeService: ScreenTimeServiceProtocol = DependencyContainer[\.screenTimeService]
    ) {
        self.navigationController = navigationController
        self.modelContainer = modelContainer
        self.screenTimeService = screenTimeService
    }

    func start() {
        let viewModel = DashboardViewModel(modelContext: modelContainer.mainContext)
        dashboardViewModel = viewModel
        viewModel.onPresentQuestCompletion = { [weak self] stats in
            self?.presentQuestCompletion(stats: stats)
        }
        viewModel.onDismissQuestCompletion = { [weak self] in
            self?.dismissQuestCompletionIfPresented()
        }
        #if os(iOS) || os(visionOS)
        viewModel.onPresentLockdownFlow = { [weak self] in
            self?.presentLockdownAppPicker()
        }
        #endif

        let root = DashboardView(viewModel: viewModel)
            .modelContainer(modelContainer)
        let initialVC = UIHostingController(rootView: root)
        initialVC.view.backgroundColor = AppTheme.UIKitColors.background

        navigationController.pushViewController(initialVC, animated: false)
    }

    func presentQuestCompletion(stats: [CharacterStat]) {
        guard let viewModel = dashboardViewModel else { return }
        let root = QuestCompletionView(stats: stats, viewModel: viewModel)
            .modelContainer(modelContainer)
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = AppTheme.UIKitColors.background
        hosting.modalPresentationStyle = .pageSheet
        if let sheet = hosting.sheetPresentationController {
            let detentId = UISheetPresentationController.Detent.Identifier("questCompletion")
            let contentHeight = QuestCompletionView.preferredSheetDetentHeight(statCount: stats.count)
            sheet.detents = [
                .custom(identifier: detentId) { context in
                    min(contentHeight, context.maximumDetentValue)
                }
            ]
            sheet.selectedDetentIdentifier = detentId
            sheet.prefersGrabberVisible = true
        }
        questCompletionHostingController = hosting
        navigationController.present(hosting, animated: true)
    }

    private func dismissQuestCompletionIfPresented() {
        guard let presented = questCompletionHostingController ?? navigationController.presentedViewController else {
            return
        }
        presented.dismiss(animated: true) { [weak self] in
            self?.questCompletionHostingController = nil
        }
    }

    #if os(iOS) || os(visionOS)
    func presentLockdownAppPicker() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.screenTimeService.requestAuthorization()
            } catch {
                return
            }

            let root = LockdownAppPickerView(
                onApply: { [weak self] selection in
                    guard let self else { return }
                    self.screenTimeService.applyShields(selection: selection)
                    self.dismissLockdownIfPresented()
                },
                onCancel: { [weak self] in
                    self?.dismissLockdownIfPresented()
                },
                onClearShields: { [weak self] in
                    guard let self else { return }
                    self.screenTimeService.removeShields()
                    self.dismissLockdownIfPresented()
                }
            )

            let hosting = UIHostingController(rootView: root)
            hosting.view.backgroundColor = AppTheme.UIKitColors.background
            hosting.modalPresentationStyle = .pageSheet
            if let sheet = hosting.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            self.lockdownHostingController = hosting
            self.navigationController.present(hosting, animated: true)
        }
    }

    private func dismissLockdownIfPresented() {
        guard let presented = lockdownHostingController ?? navigationController.presentedViewController else {
            return
        }
        presented.dismiss(animated: true) { [weak self] in
            self?.lockdownHostingController = nil
        }
    }
    #endif
}

struct CoordinatorView: UIViewControllerRepresentable {
    let coordinator: AppCoordinator
    
    // SwiftUI llama a este método una vez para crear el controlador de UIKit
    func makeUIViewController(context: Context) -> UINavigationController {
        coordinator.start() // Arrancamos el flujo
        return coordinator.navigationController // Le entregamos el control a SwiftUI
    }
    
    // Este método es obligatorio, pero lo dejamos vacío porque nuestro Coordinator gestiona las actualizaciones
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
