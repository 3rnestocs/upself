//
//  SettingsView.swift
//  UpSelf
//
//  About + DEBUG game clock (simulation only).
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Bindable private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text(L10n.Settings.appNameLabel)
                        .font(AppTheme.Fonts.ui(.body))
                    Spacer()
                    Text("UpSelf")
                        .font(AppTheme.Fonts.ui(.body))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }
                HStack {
                    Text(L10n.Settings.versionLabel)
                        .font(AppTheme.Fonts.ui(.body))
                    Spacer()
                    Text(appVersion)
                        .font(AppTheme.Fonts.mono(.body))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }
            } header: {
                Text(L10n.Settings.aboutSection)
            }

            Section {
                if let profile = profiles.first {
                    Stepper(value: Binding(
                        get: { profile.lockdownMinEpicQuestsToClear },
                        set: { viewModel.updateLockdownMinEpic(for: profile, rawValue: $0) }
                    ), in: 0...20, step: 1) {
                        Text(L10n.Settings.lockdownMinEpicLabel)
                            .font(AppTheme.Fonts.ui(.body))
                    }
                    .tint(AppTheme.Colors.accentXP)

                    Stepper(value: Binding(
                        get: { profile.lockdownMinHardQuestsToClear },
                        set: { viewModel.updateLockdownMinHard(for: profile, rawValue: $0) }
                    ), in: 0...20, step: 1) {
                        Text(L10n.Settings.lockdownMinHardLabel)
                            .font(AppTheme.Fonts.ui(.body))
                    }
                    .tint(AppTheme.Colors.accentXP)

                    if let message = viewModel.lockdownPersistenceError {
                        Text(message)
                            .font(AppTheme.Fonts.mono(.caption2))
                            .foregroundStyle(AppTheme.Colors.alertHP)
                    }
                }
            } header: {
                Text(L10n.Settings.lockdownSection)
            } footer: {
                Text(L10n.Settings.lockdownFooter)
                    .font(AppTheme.Fonts.mono(.caption2))
            }

            Section {
                Button {
                    viewModel.requestLocalDataResetConfirmation()
                } label: {
                    Text(L10n.Settings.dataResetButton)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(AppTheme.Colors.alertHP)

                if let resetDataStatus = viewModel.resetDataStatus {
                    Text(resetDataStatus)
                        .font(AppTheme.Fonts.mono(.caption2))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }
            } header: {
                Text(L10n.Settings.dataSection)
            } footer: {
                Text(L10n.Settings.dataResetFooter)
                    .font(AppTheme.Fonts.mono(.caption2))
            }

            #if DEBUG
            Section {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(L10n.Settings.effectiveGameDay)
                        .font(AppTheme.Fonts.ui(.caption))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    Text(viewModel.formattedDraftGameDayLabel())
                        .font(AppTheme.Fonts.mono(.headline))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
                .listRowInsets(EdgeInsets(
                    top: AppTheme.Spacing.sm,
                    leading: AppTheme.Spacing.md,
                    bottom: AppTheme.Spacing.sm,
                    trailing: AppTheme.Spacing.md
                ))

                Stepper(value: $viewModel.draftDayOffset, in: -14...14, step: 1) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(L10n.Settings.gameClockLabel)
                            .font(AppTheme.Fonts.ui(.body))
                        Text(L10n.Settings.gameClockOffsetDescription(viewModel.draftDayOffset))
                            .font(AppTheme.Fonts.mono(.caption))
                            .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    }
                }
                .tint(AppTheme.Colors.accentXP)

                if viewModel.hasUnappliedGameDayDraft {
                    Text(L10n.Settings.draftPending)
                        .font(AppTheme.Fonts.mono(.caption))
                        .foregroundStyle(AppTheme.Colors.amber)
                }

                Button {
                    viewModel.applyGameDayDraft()
                } label: {
                    Text(L10n.Settings.applyGameDay)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(!viewModel.hasUnappliedGameDayDraft)
                .tint(AppTheme.Colors.accentXP)

                Button {
                    viewModel.useRealGameDay()
                } label: {
                    Text(L10n.Settings.useRealToday)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(AppTheme.Colors.secondaryLabel)

                Button {
                    viewModel.debugResetMissedDailyWatermark()
                } label: {
                    Text(L10n.Settings.resetWatermark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(AppTheme.Colors.alertHP)

                if let watermarkStatus = viewModel.developerWatermarkStatus {
                    Text(watermarkStatus)
                        .font(AppTheme.Fonts.mono(.caption2))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }
            } header: {
                Text(L10n.Settings.developerSection)
            } footer: {
                Text(L10n.Settings.gameClockFooter)
            }
            #endif
        }
        .navigationTitle(L10n.Settings.title)
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
