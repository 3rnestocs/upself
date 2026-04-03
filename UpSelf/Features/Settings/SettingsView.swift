//
//  SettingsView.swift
//  UpSelf
//
//  About + DEBUG game clock (simulation only).
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Bindable private var gameClock = DependencyContainer[\.gameClock]

    /// Draft offset; tap **Apply** to use it for dailies / penalties (saved in DEBUG).
    @State private var draftDayOffset: Int = 0
    @State private var watermarkStatus: String?

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }

    private var hasUnappliedDraft: Bool {
        draftDayOffset != gameClock.dayOffset
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
                        set: { newValue in
                            profile.lockdownMinEpicQuestsToClear = max(0, min(20, newValue))
                            normalizeLockdownMinimums(profile)
                            try? modelContext.save()
                        }
                    ), in: 0...20, step: 1) {
                        Text(L10n.Settings.lockdownMinEpicLabel)
                            .font(AppTheme.Fonts.ui(.body))
                    }
                    .tint(AppTheme.Colors.accentXP)

                    Stepper(value: Binding(
                        get: { profile.lockdownMinHardQuestsToClear },
                        set: { newValue in
                            profile.lockdownMinHardQuestsToClear = max(0, min(20, newValue))
                            normalizeLockdownMinimums(profile)
                            try? modelContext.save()
                        }
                    ), in: 0...20, step: 1) {
                        Text(L10n.Settings.lockdownMinHardLabel)
                            .font(AppTheme.Fonts.ui(.body))
                    }
                    .tint(AppTheme.Colors.accentXP)
                }
            } header: {
                Text(L10n.Settings.lockdownSection)
            } footer: {
                Text(L10n.Settings.lockdownFooter)
                    .font(AppTheme.Fonts.mono(.caption2))
            }

            #if DEBUG
            Section {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(L10n.Settings.effectiveGameDay)
                        .font(AppTheme.Fonts.ui(.caption))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    Text(gameClock.formattedGameCalendarDayLabel(dayOffset: draftDayOffset))
                        .font(AppTheme.Fonts.mono(.headline))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
                .listRowInsets(EdgeInsets(
                    top: AppTheme.Spacing.sm,
                    leading: AppTheme.Spacing.md,
                    bottom: AppTheme.Spacing.sm,
                    trailing: AppTheme.Spacing.md
                ))

                Stepper(value: $draftDayOffset, in: -14...14, step: 1) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(L10n.Settings.gameClockLabel)
                            .font(AppTheme.Fonts.ui(.body))
                        Text(L10n.Settings.gameClockOffsetDescription(draftDayOffset))
                            .font(AppTheme.Fonts.mono(.caption))
                            .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    }
                }
                .tint(AppTheme.Colors.accentXP)

                if hasUnappliedDraft {
                    Text(L10n.Settings.draftPending)
                        .font(AppTheme.Fonts.mono(.caption))
                        .foregroundStyle(AppTheme.Colors.amber)
                }

                Button {
                    gameClock.dayOffset = draftDayOffset
                } label: {
                    Text(L10n.Settings.applyGameDay)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(!hasUnappliedDraft)
                .tint(AppTheme.Colors.accentXP)

                Button {
                    draftDayOffset = 0
                    gameClock.dayOffset = 0
                } label: {
                    Text(L10n.Settings.useRealToday)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(AppTheme.Colors.secondaryLabel)

                Button {
                    do {
                        try MissedDailyPenaltyService.debugResetEvaluationWatermark(
                            context: modelContext,
                            clock: gameClock
                        )
                        watermarkStatus = String(localized: L10n.Settings.watermarkResetDone)
                    } catch {
                        watermarkStatus = String(localized: L10n.Settings.watermarkResetFailed)
                    }
                } label: {
                    Text(L10n.Settings.resetWatermark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(AppTheme.Colors.alertHP)

                if let watermarkStatus {
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
        #if DEBUG
        .onAppear {
            draftDayOffset = gameClock.dayOffset
        }
        #endif
    }

    private func normalizeLockdownMinimums(_ profile: UserProfile) {
        if profile.lockdownMinEpicQuestsToClear == 0 && profile.lockdownMinHardQuestsToClear == 0 {
            profile.lockdownMinEpicQuestsToClear = 1
            profile.lockdownMinHardQuestsToClear = 2
        }
    }
}
