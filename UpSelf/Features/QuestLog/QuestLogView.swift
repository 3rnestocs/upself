//
//  QuestLogView.swift
//  UpSelf
//
//  Action center: filter dailies vs one-offs; complete via swipe. If lockdown engages while this screen is visible, we pop back to the HUD.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private enum QuestLogFilter: Hashable {
    case daily
    case oneOff
}

struct QuestLogView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \Quest.title) private var allQuests: [Quest]

    @Bindable private var gameClock = DependencyContainer[\.gameClock]

    private let viewModel: QuestLogViewModel

    @State private var filter: QuestLogFilter = .daily
    @State private var showInstructions = false

    init(viewModel: QuestLogViewModel) {
        self.viewModel = viewModel
    }

    private var profile: UserProfile? { profiles.first }

    // Estado local que guarda la lista ya filtrada y ordenada.
    @State private var visibleQuests: [Quest] = []

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Picker("", selection: $filter) {
                Text(L10n.QuestLog.filterDaily).tag(QuestLogFilter.daily)
                Text(L10n.QuestLog.filterOneOff).tag(QuestLogFilter.oneOff)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.QuestLog.filterAccessibility)

            if visibleQuests.isEmpty {
                Text(L10n.QuestLog.empty)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                List {
                    ForEach(visibleQuests, id: \.id) { quest in
                        questRow(quest)
                            .listRowInsets(EdgeInsets(
                                top: AppTheme.Spacing.xs,
                                leading: 0,
                                bottom: AppTheme.Spacing.xs,
                                trailing: 0
                            ))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Colors.background)
        .onAppear {
            updateQuests() // Calcula cuando entras a la pantalla
            if profile?.isInLockdown == true {
                viewModel.onLockdownEngagedExit?()
            }
        }
        .onChange(of: profile?.isInLockdown) { old, new in
            if new == true, old != true {
                viewModel.onLockdownEngagedExit?()
            }
        }
        .onChange(of: allQuests) { _, _ in
            updateQuests() // Recalcula si creas o completas una misión
        }
        .onChange(of: filter) { _, _ in
            updateQuests() // Recalcula si cambias la pestaña (Diarias/Puntuales)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInstructions = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: L10n.QuestLog.instructionsButtonAccessibility))
            }
        }
        .alert(String(localized: L10n.QuestLog.instructionsTitle), isPresented: $showInstructions) {
            Button(String(localized: L10n.Common.ok), role: .cancel) {}
        } message: {
            Text(L10n.QuestLog.instructionsBody)
        }
    }

    private func completeQuestFromSwipe(_ quest: Quest) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        let q = quest
        DispatchQueue.main.async {
            viewModel.completePersistedQuest(q)
        }
    }

    private func updateQuests() {
        guard let id = profile?.id else { return }
        let ref = gameClock.now // Tomamos la hora una sola vez
        
        // 1. Filtrar
        let subset = allQuests.filter { quest in
            // Al hacer esto aquí, obligamos a SwiftData a resolver el "Fault"
            // antes de que el usuario interactúe.
            guard quest.user?.id == id else { return false }
            switch filter {
            case .daily: return quest.isDaily
            case .oneOff: return !quest.isDaily
            }
        }
        
        // 2. Ordenar y asignar al estado de la vista
        visibleQuests = subset.sorted { a, b in
            let ad = a.displayAsCompleted(referenceDate: ref)
            let bd = b.displayAsCompleted(referenceDate: ref)
            if ad != bd { return !ad && bd }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    @ViewBuilder
    private func questRow(_ quest: Quest) -> some View {
        let ref = gameClock.now
        let done = quest.displayAsCompleted(referenceDate: ref)
        let canComplete = quest.canComplete(referenceDate: ref)
        let content = QuestLogRowCard(
            quest: quest,
            done: done,
            canComplete: canComplete,
            tierBlockedInLockdown: false
        )

        if canComplete {
            content
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        completeQuestFromSwipe(quest)
                    } label: {
                        Label {
                            Text(L10n.HUD.questCompleteAction)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .tint(AppTheme.Colors.amber)
                }
        } else {
            content
        }
    }
}
