//
//
// AliasSyncConfigurationView.swift
// Proton Pass - Created on 02/08/2024.
// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.
//

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

private enum AliasSyncConfigurationSheetState {
    case domain
    case mailbox
    case vault
}

struct AliasSyncConfigurationView: View {
    @StateObject private var viewModel = AliasSyncConfigurationViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var sheetState: AliasSyncConfigurationSheetState?

    var body: some View {
        VStack(alignment: .leading) {
            Section {
                SynchroElementRow(title: "Default domain for aliases",
                                  content: viewModel.defaultDomain?.domain ?? "") {
                    sheetState = .domain
                }
            } header: {
                Text("Domain")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.bold)
            }

            Section {
                SynchroElementRow(title: "Default mailbox for aliases",
                                  content: viewModel.defaultMailbox?.email ?? "") {
                    sheetState = .mailbox
                }
            } header: {
                Text("Mailboxes")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.bold)
            }

            if viewModel.showSyncSection {
                Section {
                    if viewModel.pendingSyncDisabledAliases > 0 {
                        AliasSyncExplanationView(missingAliases: viewModel.pendingSyncDisabledAliases) {
                            viewModel.showSimpleLoginAliasesActivation()
                        }
                    } else {
                        SelectedSyncVaultRow(vault: viewModel.selectedVault?.vault) {
                            sheetState = .vault
                        }
                    }
                } header: {
                    Text("SimpleLogin sync")
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .navigationTitle("Aliases")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .optionalSheet(binding: $sheetState) { state in
            sheetContent(for: state)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .showSpinner(viewModel.loading)
        .navigationStackEmbeded()
    }

    @ViewBuilder
    private func sheetContent(for state: AliasSyncConfigurationSheetState) -> some View {
        switch state {
        case .domain:
            GenericSelectionView(title: "Default domain for aliases",
                                 selected: $viewModel.defaultDomain,
                                 selections: viewModel.domains)
        case .mailbox:
            GenericSelectionView(title: "Default mailbox for aliases",
                                 selected: $viewModel.defaultMailbox,
                                 selections: viewModel.mailboxes)
        case .vault:
            VaultSelectionView(selectedVault: $viewModel.selectedVault,
                               vaults: viewModel.vaults)
        }
    }
}

private struct SynchroElementRow: View {
    let title: LocalizedStringKey
    let content: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            selectedElement
                .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .roundedEditableSection()
        .padding(.bottom, 10)
    }

    private var selectedElement: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)

                Text(content)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            Spacer()

            Image(uiImage: IconProvider.chevronRight)
                .resizable()
                .scaledToFit()
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxHeight: 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .contentShape(.rect)
    }
}

private extension AliasSyncConfigurationView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor1,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }
    }
}

private protocol TitleRepresentable {
    var title: String { get }
}

extension Mailbox: TitleRepresentable {
    var title: String {
        email
    }
}

extension Domain: TitleRepresentable {
    var title: String {
        domain
    }
}

private struct GenericSelectionView<Selection: Identifiable & Equatable & TitleRepresentable>: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    @Binding var selected: Selection?
    let selections: [Selection]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(selections) { element in
                        let isSelected = element == selected
                        Button(action: {
                            selected = element
                            dismiss()
                        }, label: {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text(element.title)
                                        .foregroundStyle(PassColor.textNorm.toColor)
                                }

                                Spacer()

                                if isSelected {
                                    Image(uiImage: IconProvider.checkmark)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(PassColor.interactionNorm.toColor)
                                        .frame(maxHeight: 20)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .contentShape(.rect)
                            .animation(.default, value: isSelected)
                        })
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
            }
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: selected)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .adaptiveForegroundStyle(PassColor.textNorm.toColor)
                }
            }
        }
    }
}
