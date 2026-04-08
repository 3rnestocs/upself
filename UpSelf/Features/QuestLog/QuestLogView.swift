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

// Defined here (not private) so QuestLogViewModel can reference it.
enum QuestLogFilter: Hashable {
    case daily
    case oneOff
    case goal
}

struct QuestLogView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \Quest.title) private var allQuests: [Quest]

    @Environment(\.gameClock) private var gameClock
    @Environment(\.scenePhase) private var scenePhase

    private let viewModel: QuestLogViewModel

    @State private var filter: QuestLogFilter = .daily
    /// Avoids scheduling two pops when `onAppear` and `onChange(of: isInLockdown)` both see lockdown on first paint.
    @State private var didScheduleLockdownExit = false

    init(viewModel: QuestLogViewModel) {
        self.viewModel = viewModel
    }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Picker("", selection: $filter) {
                Text(L10n.QuestLog.filterDaily).tag(QuestLogFilter.daily)
                Text(L10n.QuestLog.filterOneOff).tag(QuestLogFilter.oneOff)
                Text(L10n.QuestLog.filterGoal).tag(QuestLogFilter.goal)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.QuestLog.filterAccessibility)

            if viewModel.visibleQuests.isEmpty {
                Text(L10n.QuestLog.empty)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                List {
                    ForEach(viewModel.visibleQuests, id: \.id) { quest in
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
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .onAppear {
            viewModel.refreshQuests(allQuests: allQuests, profiles: profiles, filter: filter, clock: gameClock)
            scheduleLockdownExitIfNeeded()
        }
        .onChange(of: profile?.isInLockdown) { old, new in
            if new == true, old != true {
                scheduleLockdownExitIfNeeded()
            }
        }
        .onChange(of: allQuests) { _, q in
            viewModel.refreshQuests(allQuests: q, profiles: profiles, filter: filter, clock: gameClock)
        }
        .onChange(of: filter) { _, f in
            viewModel.refreshQuests(allQuests: allQuests, profiles: profiles, filter: f, clock: gameClock)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refreshQuests(allQuests: allQuests, profiles: profiles, filter: filter, clock: gameClock)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentQuestLogInstructions()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: L10n.QuestLog.instructionsButtonAccessibility))
            }
        }
    }

    private func scheduleLockdownExitIfNeeded() {
        guard profile?.isInLockdown == true else { return }
        guard !didScheduleLockdownExit else { return }
        didScheduleLockdownExit = true
        viewModel.onLockdownEngagedExit?()
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
