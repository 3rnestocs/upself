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

    private var dashboardViewModel: DashboardViewModel?
    private weak var createQuestHostingController: UIViewController?

    init(
        navigationController: UINavigationController = UINavigationController(),
        modelContainer: ModelContainer
    ) {
        self.navigationController = navigationController
        self.modelContainer = modelContainer
    }

    func start() {
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

        let root = DashboardView(viewModel: viewModel)
            .modelContainer(modelContainer)
        let initialVC = UIHostingController(rootView: root)
        initialVC.view.backgroundColor = AppTheme.UIKitColors.background

        navigationController.pushViewController(initialVC, animated: false)
    }

    func presentCreateQuest() {
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
        navigationController.pushViewController(hosting, animated: true)
    }

    func pushQuestLog() {
        let viewModel = QuestLogViewModel(modelContext: modelContainer.mainContext)
        let root = QuestLogView(viewModel: viewModel)
            .modelContainer(modelContainer)
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = AppTheme.UIKitColors.background
        hosting.navigationItem.title = String(localized: L10n.QuestLog.title)
        navigationController.pushViewController(hosting, animated: true)
    }

    private func dismissCreateQuestIfPresented() {
        guard let hosting = createQuestHostingController else { return }
        hosting.dismiss(animated: true) { [weak self] in
            self?.createQuestHostingController = nil
        }
    }
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
