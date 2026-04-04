//
//  GlobalUIKitAlertPresenter.swift
//  UpSelf
//
//  Queued `UIAlertController` presentation from the tab bar root (window + transition safety).
//

import UIKit

/// Centralizes global alert queueing and host selection for the whole app.
@MainActor
final class GlobalUIKitAlertPresenter {

    private weak var tabBarController: UITabBarController?
    private var globalAlertQueue: [(@escaping () -> Void) -> Void] = []
    private var isProcessingGlobalAlertQueue = false

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    /// One alert at a time. `builder` receives `finish`, which **must** run when the alert path is done (including button taps).
    func enqueue(_ builder: @escaping (@escaping () -> Void) -> Void) {
        globalAlertQueue.append(builder)
        processGlobalAlertQueueIfNeeded()
    }

    /// Queued alert with a single OK button.
    func presentOKAlert(title: String?, message: String?, okTitle: String, onOK: (() -> Void)? = nil) {
        enqueue { [weak self] finish in
            guard let self, let tab = tabBarController else {
                finish()
                return
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: okTitle, style: .default) { _ in
                onOK?()
                finish()
            })
            presentOnIdleAlertHost(alert, animated: true, root: tab, ifUnableToPresent: finish)
        }
    }

    /// Presents a fully configured alert on the idle host (same rules as other queue items). For custom actions (e.g. navigation before `finish`).
    func presentOnIdleHost(_ alert: UIAlertController, animated: Bool = true, ifUnableToPresent: @escaping () -> Void) {
        guard let tab = tabBarController else {
            ifUnableToPresent()
            return
        }
        presentOnIdleAlertHost(alert, animated: animated, root: tab, ifUnableToPresent: ifUnableToPresent)
    }

    /// Queued alert with cancel + one action (e.g. confirm / destructive).
    func presentConfirmAlert(
        title: String?,
        message: String?,
        cancelTitle: String,
        actionTitle: String,
        actionStyle: UIAlertAction.Style = .default,
        onCancel: (() -> Void)? = nil,
        onAction: @escaping () -> Void
    ) {
        enqueue { [weak self] finish in
            guard let self, let tab = tabBarController else {
                finish()
                return
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
                onCancel?()
                finish()
            })
            alert.addAction(UIAlertAction(title: actionTitle, style: actionStyle) { _ in
                onAction()
                finish()
            })
            presentOnIdleAlertHost(alert, animated: true, root: tab, ifUnableToPresent: finish)
        }
    }

    // MARK: - Queue

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

    /// Presents when the top VC is in a window and not mid-transition; retries on the next run loop if needed.
    private func presentOnIdleAlertHost(
        _ alert: UIAlertController,
        animated: Bool,
        root: UITabBarController,
        ifUnableToPresent: @escaping () -> Void,
        idleRetryAttempt: Int = 0
    ) {
        let host = Self.topMostViewController(from: root)
        let hostNotReady = !host.isViewLoaded
            || host.view.window == nil
            || host.isBeingDismissed
            || host.isMovingToParent
            || host.isBeingPresented

        if hostNotReady {
            if idleRetryAttempt >= 24 {
                ifUnableToPresent()
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.presentOnIdleAlertHost(
                    alert,
                    animated: animated,
                    root: root,
                    ifUnableToPresent: ifUnableToPresent,
                    idleRetryAttempt: idleRetryAttempt + 1
                )
            }
            return
        }
        host.present(alert, animated: animated) {
            if host.presentedViewController !== alert {
                ifUnableToPresent()
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
}
