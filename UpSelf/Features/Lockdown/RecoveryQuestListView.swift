//
//  RecoveryQuestListView.swift
//  UpSelf
//
//  Pushed screen: hard & epic quests only (lockdown recovery). Same row UX as Quest Log + confirm alert.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RecoveryQuestListView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \Quest.title) private var allQuests: [Quest]

    @Environment(\.gameClock) private var gameClock
    @Environment(\.scenePhase) private var scenePhase

    private let viewModel: RecoveryQuestListViewModel

    init(viewModel: RecoveryQuestListViewModel) {
        self.viewModel = viewModel
    }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if !viewModel.hasAnyQuest {
                Text(L10n.Lockdown.recoveryEmpty)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                List {
                    if !viewModel.epicQuests.isEmpty {
                        Section {
                            ForEach(viewModel.epicQuests, id: \.id) { quest in
                                recoveryQuestRow(quest)
                                    .listRowInsets(EdgeInsets(
                                        top: AppTheme.Spacing.xs,
                                        leading: 0,
                                        bottom: AppTheme.Spacing.xs,
                                        trailing: 0
                                    ))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text(L10n.Lockdown.recoverySectionEpicHeader(
                                done: profile?.lockdownEpicCompletions ?? 0,
                                needed: profile?.lockdownMinEpicQuestsToClear ?? 0
                            ))
                            .font(AppTheme.Fonts.ui(.subheadline))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.accentXP)
                            .textCase(nil)
                        }
                    }
                    if !viewModel.hardQuests.isEmpty {
                        Section {
                            ForEach(viewModel.hardQuests, id: \.id) { quest in
                                recoveryQuestRow(quest)
                                    .listRowInsets(EdgeInsets(
                                        top: AppTheme.Spacing.xs,
                                        leading: 0,
                                        bottom: AppTheme.Spacing.xs,
                                        trailing: 0
                                    ))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text(L10n.Lockdown.recoverySectionHardHeader(
                                done: profile?.lockdownHardCompletions ?? 0,
                                needed: profile?.lockdownMinHardQuestsToClear ?? 0
                            ))
                            .font(AppTheme.Fonts.ui(.subheadline))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.accentXP)
                            .textCase(nil)
                        }
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
            viewModel.refresh(allQuests: allQuests, profiles: profiles, clock: gameClock)
        }
        .onChange(of: allQuests) { _, q in
            viewModel.refresh(allQuests: q, profiles: profiles, clock: gameClock)
        }
        .onChange(of: profiles) { _, p in
            viewModel.refresh(allQuests: allQuests, profiles: p, clock: gameClock)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refresh(allQuests: allQuests, profiles: profiles, clock: gameClock)
            }
        }
    }

    private func requestComplete(_ quest: Quest) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        let questID = quest.id
        viewModel.presentRecoveryQuestCompleteConfirm(questTitle: quest.title) {
            DispatchQueue.main.async {
                guard let q = self.allQuests.first(where: { $0.id == questID }) else { return }
                self.viewModel.completePersistedQuest(q)
            }
        }
    }

    @ViewBuilder
    private func recoveryQuestRow(_ quest: Quest) -> some View {
        let ref = gameClock.now
        let episodeStart = profile?.lockdownEpisodeStart
        let done = quest.recoveryListDisplayCompleted(referenceDate: ref, lockdownEpisodeStart: episodeStart)
        let canComplete = quest.recoveryListCanComplete(referenceDate: ref, lockdownEpisodeStart: episodeStart)
        let tierBlockedInLockdown = viewModel.isTierBlockedInLockdown(quest, profile: profile)
        let content = QuestLogRowCard(
            quest: quest,
            done: done,
            canComplete: canComplete,
            tierBlockedInLockdown: tierBlockedInLockdown
        )

        if canComplete, !tierBlockedInLockdown {
            content
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        requestComplete(quest)
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
