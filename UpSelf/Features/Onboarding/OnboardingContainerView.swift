//
//  OnboardingContainerView.swift
//  UpSelf
//
//  Full-screen onboarding shown on first launch. Presents a welcome page, a brief
//  concept explanation, a stat overview, a lockdown warning, a personalisation pick,
//  and a final import step that seeds the starter quests before handing control to the main app.
//

import SwiftData
import SwiftUI

struct OnboardingContainerView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page: Int = 0
    @State private var showImportPage = false
    @State private var viewModel: OnboardingViewModel
    @State private var priorityStat: CharacterAttribute? = nil
    @State private var importPageReady = false
    @State private var dotCount = 0

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: OnboardingViewModel(modelContext: modelContext))
    }

    var body: some View {
        ZStack {
            if !showImportPage {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    conceptPage.tag(1)
                    statsPage.tag(2)
                    lockdownPage.tag(3)
                    personalizationPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .transition(.opacity)
            } else {
                importPage
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.35), value: showImportPage)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        OnboardingPageLayout(
            icon: AppTheme.Icons.appLogo,
            title: String(localized: L10n.Onboarding.welcomeTitle),
            bodyText: String(localized: L10n.Onboarding.welcomeBody),
            primaryLabel: String(localized: L10n.Onboarding.actionNext),
            primaryAction: { withAnimation { page = 1 } },
            iconSize: 96
        )
    }

    private var conceptPage: some View {
        OnboardingPageLayout(
            icon: AppTheme.Icons.onboardingConcept,
            title: String(localized: L10n.Onboarding.conceptTitle),
            bodyText: String(localized: L10n.Onboarding.conceptBody),
            primaryLabel: String(localized: L10n.Onboarding.actionNext),
            primaryAction: { withAnimation { page = 2 } }
        )
    }

    private var statsPage: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.sm) {
                Text(L10n.Onboarding.statsTitle)
                    .font(AppTheme.Fonts.ui(.title2))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .multilineTextAlignment(.center)

                Text(L10n.Onboarding.statsBody)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(CharacterAttribute.allCases, id: \.self) { stat in
                    HStack(spacing: AppTheme.Spacing.md) {
                        AppTheme.Icons.icon(for: stat).view(size: 20)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.Stats.title(for: stat))
                                .font(AppTheme.Fonts.ui(.callout))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.white.opacity(0.9))
                            Text(L10n.Stats.description(for: stat))
                                .font(AppTheme.Fonts.ui(.footnote))
                                .foregroundStyle(AppTheme.Colors.secondaryLabel)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                }
            }

            Spacer()

            Button(L10n.Onboarding.actionNext) { withAnimation { page = 3 } }
                .buttonStyle(OnboardingPrimaryButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.bottom, AppTheme.Spacing.xl)
    }

    private var lockdownPage: some View {
        OnboardingPageLayout(
            icon: AppTheme.Icons.onboardingLockdown,
            title: String(localized: L10n.Onboarding.lockdownTitle),
            bodyText: String(localized: L10n.Onboarding.lockdownBody),
            primaryLabel: String(localized: L10n.Onboarding.actionUnderstood),
            primaryAction: { withAnimation { page = 4 } }
        )
    }

    private var personalizationPage: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            personalizationHeader
            personalizationStatList
            Spacer()
            personalizationCTA
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.bottom, AppTheme.Spacing.xl)
    }

    private var personalizationHeader: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            AppTheme.Icons.onboardingPersonalization.view(size: 56)

            Text(L10n.Onboarding.personalizationTitle)
                .font(AppTheme.Fonts.ui(.title2))
                .fontWeight(.bold)
                .foregroundStyle(Color.white.opacity(0.92))
                .multilineTextAlignment(.center)

            Text(L10n.Onboarding.personalizationBody)
                .font(AppTheme.Fonts.ui(.subheadline))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var personalizationStatList: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(CharacterAttribute.allCases, id: \.self) { stat in
                personalizationStatRow(stat)
            }
        }
    }

    private func personalizationStatRow(_ stat: CharacterAttribute) -> some View {
        let selected = priorityStat == stat
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                priorityStat = selected ? nil : stat
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                AppTheme.Icons.icon(for: stat).view(size: 20)
                    .frame(width: 36)
                Text(L10n.Stats.title(for: stat))
                    .font(AppTheme.Fonts.ui(.callout))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.opacity(0.9))
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                selected ? AppTheme.Colors.accentXP.opacity(0.15) : Color.white.opacity(0.05),
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
            )
        }
        .buttonStyle(.plain)
    }

    private var personalizationCTA: some View {
        Button(priorityStat == nil ? L10n.Onboarding.actionSkip : L10n.Onboarding.actionNext) {
            withAnimation { showImportPage = true }
        }
        .buttonStyle(OnboardingPrimaryButtonStyle())
    }

    private var importPage: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.sm) {
                AppTheme.Icons.appLogo.view(size: 120)

                Text(L10n.Onboarding.importTitle)
                    .font(AppTheme.Fonts.ui(.title))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                questPreviewCard
                    .padding(.vertical, AppTheme.Spacing.sm)
                
                if let error = viewModel.importError {
                    Text(error)
                        .font(AppTheme.Fonts.ui(.footnote))
                        .foregroundStyle(AppTheme.Colors.alertHP)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    Button(L10n.Onboarding.actionRetry) {
                        importPageReady = false
                        dotCount = 0
                        runImport()
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                } else if importPageReady {
                    Text(L10n.Onboarding.importReady)
                        .font(AppTheme.Fonts.ui(.subheadline))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                    
                    Button(L10n.Onboarding.actionPlay) {
                        hasCompletedOnboarding = true
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                    .transition(.opacity)
                } else {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Text(".")
                                .font(AppTheme.Fonts.mono(size: 56))
                                .foregroundStyle(AppTheme.Colors.accentXP)
                                .opacity(dotCount == i ? 1.0 : 0.2)
                                .animation(.easeInOut(duration: 0.3), value: dotCount)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .animation(.easeInOut(duration: 0.4), value: importPageReady)
        .onAppear {
            importPageReady = false
            dotCount = 0
            runImport()
        }
        .task {
            await animateDots()
        }
        .task {
            try? await Task.sleep(for: .seconds(5))
            withAnimation { importPageReady = true }
        }
    }

    private var questPreviewCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.Onboarding.previewHeader)
                    .font(AppTheme.Fonts.mono(size: 10))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .tracking(1.5)
                Spacer()
                Text(L10n.Onboarding.previewHpBar)
                    .font(AppTheme.Fonts.mono(size: 9))
                    .foregroundStyle(AppTheme.Colors.accentXP.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            VStack(spacing: 0) {
                ForEach(previewRows, id: \.kind) { row in
                    HStack(spacing: 10) {
                        AppTheme.Icons.icon(for: row.kind).view(size: 16, color: Color.white.opacity(row.done ? 0.35 : 0.85))
                            .frame(width: 20)
                        Text(row.title)
                            .font(AppTheme.Fonts.ui(size: 12))
                            .foregroundStyle(Color.white.opacity(row.done ? 0.35 : 0.85))
                            .strikethrough(row.done, color: .white.opacity(0.3))
                            .lineLimit(1)
                        Spacer()
                        Text(L10n.HUD.xpFormat(xp: row.xp))
                            .font(AppTheme.Fonts.mono(size: 11))
                            .foregroundStyle(AppTheme.Colors.accentXP.opacity(row.done ? 0.35 : 0.9))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if row.kind != previewRows.last?.kind {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 1)
                    }
                }
            }
        }
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: AppTheme.Colors.accentXP.opacity(0.08), radius: 16, y: 8)
        .shadow(color: .black.opacity(0.6), radius: 24, y: 16)
        .rotation3DEffect(.degrees(14), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var previewRows: [PreviewQuestRow] {[
        .init(kind: .vitality,  title: String(localized: L10n.Onboarding.previewQuestVitality),  xp: 6,  done: true),
        .init(kind: .mastery,   title: String(localized: L10n.Onboarding.previewQuestMastery),   xp: 6,  done: true),
        .init(kind: .willpower, title: String(localized: L10n.Onboarding.previewQuestWillpower), xp: 6,  done: false),
        .init(kind: .economy,   title: String(localized: L10n.Onboarding.previewQuestEconomy),   xp: 10, done: false),
    ]}

    private func animateDots() async {
        while !importPageReady {
            try? await Task.sleep(for: .milliseconds(500))
            dotCount = (dotCount + 1) % 3
        }
    }

    // MARK: - Actions

    private func runImport() {
        viewModel.importStarterQuests(priority: priorityStat)
    }
}

// MARK: - Reusable page layout

private struct OnboardingPageLayout: View {
    let icon: AppTheme.Icon
    let title: String
    let bodyText: String
    let primaryLabel: String
    let primaryAction: () -> Void
    var iconSize: CGFloat = 56

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            VStack(spacing: AppTheme.Spacing.sm) {
                icon.view(size: iconSize)
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Text(title)
                        .font(AppTheme.Fonts.ui(.title2))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                    
                    Text(bodyText)
                        .font(AppTheme.Fonts.ui(.body))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            Spacer()

            Button(primaryLabel, action: primaryAction)
                .buttonStyle(OnboardingPrimaryButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
}

// MARK: - Button style

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Fonts.ui(.headline))
            .foregroundStyle(AppTheme.Colors.background)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.accentXP)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - Quest preview data

private struct PreviewQuestRow {
    let kind: CharacterAttribute
    let title: String
    let xp: Int
    let done: Bool
}

