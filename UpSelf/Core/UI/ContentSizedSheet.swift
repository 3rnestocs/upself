//
//  ContentSizedSheet.swift
//  UpSelf
//
//  Reusable sheet sizing: detent height follows measured content (+ optional chrome).
//

import SwiftUI

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
                    #if canImport(UIKit)
                    let screenHeight = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .first?.screen.bounds.height ?? 852
                    #else
                    let screenHeight: CGFloat = 852
                    #endif
                    let maxDetent = screenHeight * configuration.maximumHeightFractionOfScreen
                    let target = min(contentHeight + configuration.extraChromeHeight, maxDetent)
                    detentHeight = max(target, configuration.minimumDetentHeight)
                }
                .presentationDetents([.height(detentHeight)])
                .presentationDragIndicator(configuration.showsDragIndicator ? .visible : .hidden)
        }
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
}
