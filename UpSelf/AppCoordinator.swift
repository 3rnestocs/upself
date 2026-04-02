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

    init(
        navigationController: UINavigationController = UINavigationController(),
        modelContainer: ModelContainer
    ) {
        self.navigationController = navigationController
        self.modelContainer = modelContainer
    }

    func start() {
        let viewModel = DashboardViewModel()
        let root = DashboardView(viewModel: viewModel)
            .modelContainer(modelContainer)
        let initialVC = UIHostingController(rootView: root)
        initialVC.view.backgroundColor = AppTheme.UIKitColors.background

        navigationController.pushViewController(initialVC, animated: false)
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
