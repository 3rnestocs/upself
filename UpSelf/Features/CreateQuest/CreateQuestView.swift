//
//  CreateQuestView.swift
//  UpSelf
//
//  Sheet content: define a quest (tier, attribute, daily) persisted to SwiftData.
//

import SwiftData
import SwiftUI

struct CreateQuestView: View {
    @Bindable var viewModel: CreateQuestViewModel
    @FocusState private var isTitleFieldFocused: Bool

    @Environment(\.contentSizedSheetUIKitDetentBridge) private var contentSizedSheetUIKitDetentBridge

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                headerBar

                if let message = viewModel.validationMessage {
                    Text(message)
                        .font(AppTheme.Fonts.ui(.footnote))
                        .foregroundStyle(AppTheme.Colors.alertHP)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(L10n.CreateQuest.fieldTitle)
                    .font(AppTheme.Fonts.ui(.caption))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)

                TextField("", text: $viewModel.titleText, axis: .vertical)
                    .font(AppTheme.Fonts.ui(.body))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .accessibilityLabel(L10n.CreateQuest.fieldTitle)
                    .focused($isTitleFieldFocused)
                    .padding(AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .fill(AppTheme.Colors.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .stroke(AppTheme.Colors.cardStroke, lineWidth: AppTheme.Stroke.cardLine)
                    )

                tierPicker

                attributePicker

                Toggle(isOn: $viewModel.isDaily) {
                    Text(L10n.CreateQuest.fieldDaily)
                        .font(AppTheme.Fonts.ui(.subheadline))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }
                .tint(AppTheme.Colors.accentXP)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentSizedSheetMeasureHeight()
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded {
                isTitleFieldFocused = false
            }
        )
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .contentSizedSheetUIKitDetentBridge(contentSizedSheetUIKitDetentBridge)
    }

    private var headerBar: some View {
        HStack {
            Button {
                viewModel.cancel()
            } label: {
                Text(L10n.CreateQuest.cancel)
                    .font(AppTheme.Fonts.ui(.body))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(L10n.CreateQuest.navTitle)
                .font(AppTheme.Fonts.ui(.headline))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)

            Spacer()

            Button {
                viewModel.save()
            } label: {
                Text(L10n.CreateQuest.save)
                    .font(AppTheme.Fonts.ui(.body))
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.accentXP)
            }
            .buttonStyle(.plain)
        }
    }

    private var tierPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(L10n.CreateQuest.fieldTier)
                .font(AppTheme.Fonts.ui(.caption))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)

            Picker(selection: $viewModel.selectedTier) {
                ForEach(QuestRewardTier.allCases, id: \.self) { tier in
                    HStack {
                        Text(L10n.CreateQuest.tierName(tier))
                        Spacer()
                        Text("\(tier.xp)")
                            .font(AppTheme.Fonts.mono(.subheadline))
                            .foregroundStyle(AppTheme.Colors.accentXP)
                    }
                    .tag(tier)
                }
            } label: {
                Text(L10n.CreateQuest.fieldTier)
            }
            .pickerStyle(.menu)
            .tint(AppTheme.Colors.accentXP)
            .labelsHidden()
        }
    }

    private var attributePicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(L10n.CreateQuest.fieldAttribute)
                .font(AppTheme.Fonts.ui(.caption))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)

            Picker(selection: $viewModel.selectedAttribute) {
                ForEach(CharacterAttribute.allCases, id: \.self) { attr in
                    Text(L10n.Stats.title(for: attr)).tag(attr)
                }
            } label: {
                Text(L10n.CreateQuest.fieldAttribute)
            }
            .pickerStyle(.menu)
            .tint(AppTheme.Colors.accentXP)
            .labelsHidden()
        }
    }
}
