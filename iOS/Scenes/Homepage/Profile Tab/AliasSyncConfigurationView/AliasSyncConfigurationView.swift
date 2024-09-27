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

    @State private var mailboxToDelete: Mailbox?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Section {
                SynchroElementRow(title: "Default domain for aliases",
                                  content: viewModel.defaultDomain?.domain,
                                  loaded: !viewModel.domains.isEmpty,
                                  action: { sheetState = .domain })
            } header: {
                sectionHeader("Domain")
            }

            Section {
                VStack(spacing: DesignConstant.sectionPadding) {
                    VStack {
                        ForEach(viewModel.mailboxes) { mailbox in
                            MailboxElementRow(mailBox: mailbox,
                                              isDefault: mailbox == viewModel.defaultMailbox,
                                              setDefault: { mailbox in
                                                  viewModel.setDefaultMailBox(mailbox: mailbox)
                                              },
                                              delete: { mailboxToDelete = $0 })
                        }
                    }
                    .padding(DesignConstant.sectionPadding)
                    .roundedEditableSection()

                    Text("Mailbox is where emails sent to an alias are forwarded to. It's your usual mailbox, e.g. Gmail, Outlook, Proton Mail, etc.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .padding(.bottom, DesignConstant.sectionPadding)
                }
            } header: {
                HStack {
                    sectionHeader("Mailboxes")
                    Spacer()
                    Text(#localized("+ Add"))
                        .font(.callout)
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                        .frame(height: 40)
                        .padding(.horizontal, 16)
                        .background(PassColor.interactionNormMinor1.toColor)
                        .clipShape(Capsule())
                        .buttonEmbeded(role: nil, action: {})
                }
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
        .optionalSheet(binding: $mailboxToDelete) { mailbox in
            MailboxDeletionView(mailbox: mailbox,
                                otherMailboxes: viewModel.mailboxes.filter { $0 != viewModel.defaultMailbox })
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
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

private struct MailboxElementRow: View {
    let mailBox: Mailbox
    let isDefault: Bool
    let setDefault: (Mailbox) -> Void
    let delete: (Mailbox) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(mailBox.email)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    if isDefault {
                        Text(#localized("Default"))
                            .font(.footnote)
                            .foregroundStyle(PassColor.interactionNormMinor1.toColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(PassColor.interactionNormMajor2.toColor)
                            .clipShape(Capsule())
                    }
                    Text(mailBox.verified ? "21 aliases" : "Unverified mailbox")
                        .font(.footnote)
                        .foregroundStyle(PassColor.textWeak.toColor)
                }
            }

            Spacer()

            Menu(content: {
                Label(title: { Text("Make Default") },
                      icon: { Image(uiImage: IconProvider.star) })
                    .buttonEmbeded { setDefault(mailBox) }

                Divider()

                Label(title: { Text("Delete") },
                      icon: { Image(uiImage: IconProvider.trash) })
                    .buttonEmbeded { delete(mailBox) }
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: PassColor.textWeak,
                             backgroundColor: .clear,
                             accessibilityLabel: "mailbox action menu")
            })
        }
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

private struct MailboxDeletionView: View {
    @Environment(\.dismiss) private var dismiss
    let mailbox: Mailbox
    let otherMailboxes: [Mailbox]
    @State private var wantToTransferAliases = true
    @State private var selectedTransferMailbox: Mailbox?

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            VStack(spacing: DesignConstant.sectionPadding) {
                Text("Delete mailbox")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.semibold)

                Text("All aliases using the mailbox **\(mailbox.email)** will be also deleted. To keep receiving emails transfer these aliases to a different mailbox:")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                Toggle(isOn: $wantToTransferAliases) {
                    Text("Transfer aliases")
                        .foregroundStyle(PassColor.textNorm.toColor)
                }
                .toggleStyle(SwitchToggleStyle.pass)

                Divider().hidden(!wantToTransferAliases)

                HStack {
                    Text("Mailbox")
                        .foregroundStyle(PassColor.textNorm.toColor)

                    Spacer()
                    Picker("Mailbox", selection: $selectedTransferMailbox) {
                        ForEach( /* otherMailboxes */ [
                            Mailbox(mailboxID: 1, email: "test@test.com", verified: true, isDefault: false),
                            Mailbox(mailboxID: 2, email: "test2@test.com", verified: true, isDefault: false)
                        ]) { mailbox in
                            Text(mailbox.email)
                        }
                    }
                }.hidden(!wantToTransferAliases)
            }

            Spacer()

            CapsuleTextButton(title: wantToTransferAliases ? #localized("Transfer and delete mailbox") :
                #localized("Delete mailbox"),
                titleColor: PassColor.interactionNormMinor1,
                backgroundColor: PassColor.signalDanger,
                height: 48,
                action: {})

            CapsuleTextButton(title: #localized("Cancel"),
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              height: 48,
                              action: { dismiss() })
        }
        .padding(24)
    }

//    func row(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
//        HStack {
//            Text(title)
//                .foregroundStyle(PassColor.textNorm.toColor)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//            Spacer()
//
//            if isSelected {
//                Image(uiImage: IconProvider.checkmark)
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundStyle(PassColor.interactionNorm.toColor)
//                    .frame(maxHeight: 20)
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .frame(height: OptionRowHeight.compact.value)
//        .contentShape(.rect)
//        .animation(.default, value: isSelected)
//        .buttonEmbeded {
//            action()
//            dismiss()
//        }
//    }
}
