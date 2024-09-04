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
                                  content: viewModel.defaultDomain?.domain,
                                  loaded: !viewModel.domains.isEmpty,
                                  action: { sheetState = .domain })
            } header: {
                sectionHeader("Domain")
            }

            Section {
                SynchroElementRow(title: "Default mailbox for aliases",
                                  content: viewModel.defaultMailbox?.email,
                                  loaded: !viewModel.mailboxes.isEmpty,
                                  action: { sheetState = .mailbox })
            } header: {
                sectionHeader("Mailboxes")
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
                    sectionHeader("SimpleLogin sync")
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
                .presentationDetents(presentationDetents(for: state))
                .presentationDragIndicator(.visible)
        }
        .showSpinner(viewModel.loading)
        .navigationStackEmbeded()
        .alert("Error occurred",
               isPresented: $viewModel.error.mappedToBool(),
               actions: {
                   Button("Try again", action: {
                       Task {
                           await viewModel.loadData()
                       }
                   })

                   Button("Cancel", action: dismiss.callAsFunction)
               },
               message: {
                   if let error = viewModel.error {
                       Text(error.localizedDescription)
                   }
               })
        .task {
            await viewModel.loadData()
        }
    }
}

private extension AliasSyncConfigurationView {
    func sectionHeader(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .foregroundStyle(PassColor.textNorm.toColor)
            .fontWeight(.bold)
    }

    @ViewBuilder
    func sheetContent(for state: AliasSyncConfigurationSheetState) -> some View {
        switch state {
        case .domain:
            GenericSelectionView(title: "Default domain for aliases",
                                 selected: $viewModel.defaultDomain,
                                 selections: viewModel.domains,
                                 optional: true)
        case .mailbox:
            GenericSelectionView(title: "Default mailbox for aliases",
                                 selected: $viewModel.defaultMailbox,
                                 selections: viewModel.mailboxes,
                                 optional: false)
        case .vault:
            VaultSelectionView(selectedVault: $viewModel.selectedVault,
                               vaults: viewModel.vaults)
        }
    }

    func presentationDetents(for state: AliasSyncConfigurationSheetState) -> Set<PresentationDetent> {
        let customHeight: CGFloat = switch state {
        case .domain:
            // +1 for "Not selected" option
            OptionRowHeight.compact.value * CGFloat(viewModel.domains.count + 1) + 50
        case .mailbox:
            OptionRowHeight.compact.value * CGFloat(viewModel.mailboxes.count) + 50
        case .vault:
            OptionRowHeight.medium.value * CGFloat(viewModel.vaults.count) + 50
        }
        return [.height(customHeight), .large]
    }
}

private struct SynchroElementRow: View {
    let title: LocalizedStringKey
    let content: String?
    let loaded: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)

                Text(verbatim: loaded ?
                    (content ?? #localized("Not selected")) : "Placeholder text")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .if(!loaded) { view in
                        view.redacted(reason: .placeholder)
                    }
            }
            .animation(.default, value: content)

            Spacer()

            Image(uiImage: IconProvider.chevronRight)
                .resizable()
                .scaledToFit()
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxHeight: 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: OptionRowHeight.medium.value)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .buttonEmbeded {
            if loaded {
                action()
            }
        }
        .roundedEditableSection()
        .padding(.bottom)
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
    let optional: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if optional {
                        row(title: #localized("Not selected"),
                            isSelected: selected == nil,
                            action: { selected = nil })

                        PassDivider()
                    }

                    ForEach(selections) { element in
                        row(title: element.title,
                            isSelected: selected == element,
                            action: { selected = element })

                        if element != selections.last {
                            PassDivider()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: selected)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .navigationTitleText()
                }
            }
        }
    }

    func row(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)

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
        .frame(height: OptionRowHeight.compact.value)
        .contentShape(.rect)
        .animation(.default, value: isSelected)
        .buttonEmbeded {
            action()
            dismiss()
        }
    }
}
