//
//  LockdownAppPickerView.swift
//  UpSelf
//
//  Native Family Activity picker for choosing apps/categories to shield.
//

#if os(iOS) || os(visionOS)

import FamilyControls
import SwiftUI

struct LockdownAppPickerView: View {
    @State private var selection = FamilyActivitySelection()

    let onApply: (FamilyActivitySelection) -> Void
    let onCancel: () -> Void
    let onClearShields: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(L10n.Lockdown.title)
                .font(AppTheme.Fonts.ui(.headline))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)

            FamilyActivityPicker(selection: $selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: AppTheme.Spacing.sm) {
                Button(role: .cancel) {
                    onCancel()
                } label: {
                    Text(L10n.Lockdown.cancel)
                        .font(AppTheme.Fonts.ui(.footnote))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
                .buttonStyle(.bordered)

                Button {
                    onApply(selection)
                } label: {
                    Text(L10n.Lockdown.apply)
                        .font(AppTheme.Fonts.ui(.footnote))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Colors.accentXP.opacity(0.9))
            }

            Button(role: .destructive) {
                onClearShields()
            } label: {
                Text(L10n.Lockdown.clearShields)
                    .font(AppTheme.Fonts.ui(.footnote))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.bordered)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }
}

#else

/// Screen Time lockdown UI is only compiled for iOS and visionOS.
enum LockdownFeatureAvailability {
    static let isCompiled = false
}

#endif
