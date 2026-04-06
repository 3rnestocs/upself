//
//  ContentSizedSheet.swift
//  UpSelf
//
//  Reusable sheet sizing: detent height follows measured content (+ optional chrome).
//

import SwiftUI
import UIKit

/// Namespace for content-height–driven sheet presentation.
enum ContentSizedSheet {

    /// Reports the measured height of the view you attach ``SwiftUI/View/contentSizedSheetMeasureHeight()`` to.
    enum HeightPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat { 0 }
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    /// Tuning for ``SwiftUI/View/contentSizedSheetPresentation(_:)``.
    struct Configuration: Sendable {
        /// Extra height beyond the measured content (navigation bar, toolbar, safe area fudge).
        var extraChromeHeight: CGFloat
        /// Floor for the detent before the first valid measurement.
        var minimumDetentHeight: CGFloat
        /// Cap relative to the main screen height (scroll kicks in when content + chrome exceeds this).
        var maximumHeightFractionOfScreen: CGFloat
        var showsDragIndicator: Bool
        /// Starting detent before `onPreferenceChange` runs.
        var initialDetentHeight: CGFloat

        init(
            extraChromeHeight: CGFloat = 108,
            minimumDetentHeight: CGFloat = 280,
            maximumHeightFractionOfScreen: CGFloat = 0.92,
            showsDragIndicator: Bool = true,
            initialDetentHeight: CGFloat = 360
        ) {
            self.extraChromeHeight = extraChromeHeight
            self.minimumDetentHeight = minimumDetentHeight
            self.maximumHeightFractionOfScreen = maximumHeightFractionOfScreen
            self.showsDragIndicator = showsDragIndicator
            self.initialDetentHeight = initialDetentHeight
        }
    }

    fileprivate struct PresentationModifier: ViewModifier {
        let configuration: Configuration
        @State private var detentHeight: CGFloat

        init(configuration: Configuration) {
            self.configuration = configuration
            _detentHeight = State(initialValue: configuration.initialDetentHeight)
        }

        func body(content: Content) -> some View {
            content
                .onPreferenceChange(HeightPreferenceKey.self) { contentHeight in
                    guard contentHeight > 1 else { return }
                    let screenHeight = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .first?.screen.bounds.height ?? 852
                    let maxDetent = screenHeight * configuration.maximumHeightFractionOfScreen
                    let target = min(contentHeight + configuration.extraChromeHeight, maxDetent)
                    detentHeight = max(target, configuration.minimumDetentHeight)
                }
                .presentationDetents([.height(detentHeight)])
                .presentationDragIndicator(configuration.showsDragIndicator ? .visible : .hidden)
        }
    }

    /// Bridges measured height to `UISheetPresentationController` when the sheet is presented with `UIHostingController`
    /// (SwiftUI ``contentSizedSheetPresentation`` does not affect UIKit-presented sheets).
    final class UIKitDetentBridge {
        let configuration: Configuration
        private(set) var measuredContentHeight: CGFloat = 0
        var onInvalidateDetents: (() -> Void)?

        /// Coalesces `invalidateDetents()` so keyboard / layout storms do not re-enter UIKit sheet layout.
        private var invalidateDetentsWorkItem: DispatchWorkItem?
        private var lastInvalidationAtMeasurement: CGFloat = 0

        init(configuration: Configuration) {
            self.configuration = configuration
        }

        func updateMeasuredContentHeight(_ height: CGFloat) {
            guard height > 1 else { return }
            measuredContentHeight = height
            invalidateDetentsWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.flushInvalidateDetentsIfNeeded()
            }
            invalidateDetentsWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.088, execute: work)
        }

        private func flushInvalidateDetentsIfNeeded() {
            let h = measuredContentHeight
            let first = lastInvalidationAtMeasurement <= 1
            let significant = abs(h - lastInvalidationAtMeasurement) >= 6
            guard first || significant else { return }
            lastInvalidationAtMeasurement = h
            onInvalidateDetents?()
        }

        func resolvedDetentHeight(maximumDetent: CGFloat) -> CGFloat {
            let screenCap = (UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.screen.bounds.height ?? 852) * configuration.maximumHeightFractionOfScreen
            let cap = min(maximumDetent, screenCap)
            let raw: CGFloat
            if measuredContentHeight > 1 {
                raw = measuredContentHeight + configuration.extraChromeHeight
            } else {
                raw = configuration.initialDetentHeight
            }
            return min(max(raw, configuration.minimumDetentHeight), cap)
        }
    }
}

private enum ContentSizedSheetUIKitDetentBridgeKey: EnvironmentKey {
    static let defaultValue: ContentSizedSheet.UIKitDetentBridge? = nil
}

extension EnvironmentValues {
    var contentSizedSheetUIKitDetentBridge: ContentSizedSheet.UIKitDetentBridge? {
        get { self[ContentSizedSheetUIKitDetentBridgeKey.self] }
        set { self[ContentSizedSheetUIKitDetentBridgeKey.self] = newValue }
    }
}

extension View {
    /// Mark the view whose **vertical** size should drive the sheet detent (e.g. inner `VStack` inside `ScrollView`).
    func contentSizedSheetMeasureHeight() -> some View {
        background {
            GeometryReader { geo in
                Color.clear.preference(key: ContentSizedSheet.HeightPreferenceKey.self, value: geo.size.height)
            }
        }
    }

    /// Apply to the **root** of your sheet content (e.g. outer `NavigationStack`). Use with ``contentSizedSheetMeasureHeight()`` on the measured subtree.
    func contentSizedSheetPresentation(_ configuration: ContentSizedSheet.Configuration = ContentSizedSheet.Configuration()) -> some View {
        modifier(ContentSizedSheet.PresentationModifier(configuration: configuration))
    }

    /// When a ``ContentSizedSheet/UIKitDetentBridge`` is in the environment (UIKit `UIHostingController` sheet), forwards measured height and triggers detent invalidation.
    @ViewBuilder
    func contentSizedSheetUIKitDetentBridge(_ bridge: ContentSizedSheet.UIKitDetentBridge?) -> some View {
        if let bridge {
            self.onPreferenceChange(ContentSizedSheet.HeightPreferenceKey.self) { height in
                bridge.updateMeasuredContentHeight(height)
            }
        } else {
            self
        }
    }
}
