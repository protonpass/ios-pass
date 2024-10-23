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
import Factory
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
    @StateObject var router = resolve(\RouterContainer.darkWebRouter)

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
                    LazyVStack(spacing: 10) {
                        if viewModel.loading {
                            VStack {
                                Group {
                                    SkeletonBlock(tintColor: PassColor.textWeak)
                                    SkeletonBlock(tintColor: PassColor.textWeak)
                                }
                                .clipShape(Capsule())
                                .shimmering(active: true)
                            }
                        } else {
                            ForEach(viewModel.mailboxes) { mailbox in
                                MailboxElementRow(mailBox: mailbox,
                                                  isDefault: mailbox == viewModel.defaultMailbox,
                                                  showMenu: viewModel.isAdvancedAliasManagementActive,
                                                  setDefault: { mailbox in
                                                      viewModel.setDefaultMailBox(mailbox: mailbox)
                                                  },
                                                  delete: { mailboxToDelete = $0 },
                                                  verify: { router.present(sheet: .addEmail(.mailbox($0))) })
                            }
                        }
                    }
                    .padding(DesignConstant.sectionPadding)
                    .roundedEditableSection()

                    // swiftlint:disable:next line_length
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
                    if viewModel.isAdvancedAliasManagementActive, !viewModel.loading {
                        CapsuleLabelButton(icon: IconProvider.plus,
                                           title: #localized("Add"),
                                           titleColor: PassColor.interactionNormMajor2,
                                           backgroundColor: PassColor.interactionNormMinor1,
                                           maxWidth: nil) {
                            viewModel.canManageAliases ? router
                                .present(sheet: .addEmail(.mailbox(nil))) :
                                viewModel.upsell()
                        }

                        if !viewModel.canManageAliases {
                            passPlusBadge
                        }
                    }
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
        .animation(.default, value: viewModel.showSyncSection)
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
                                otherMailboxes: viewModel.mailboxes
                                    .filter { $0.mailboxID != mailbox.mailboxID && $0.verified
                                    }) { mailbox, transferId in
                viewModel.delete(mailbox: mailbox, transferMailboxId: transferId)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
        .showSpinner(viewModel.loading)
        .sheetDestinations(sheetDestination: $router.presentedSheet)
        .navigationStackEmbeded($router.path)
        .onChange(of: viewModel.defaultDomain) { domain in
            guard let domain, domain.isPremium, !viewModel.canManageAliases else {
                return
            }
            viewModel.defaultDomain = nil
            viewModel.upsell()
        }
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

    var passPlusBadge: some View {
        Image(uiImage: PassIcon.passSubscriptionUnlimited)
            .resizable()
            .scaledToFit()
            .frame(height: 24)
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
                                 optional: true,
                                 shouldUpsell: viewModel.shouldUpsell)
        case .mailbox:
            GenericSelectionView(title: "Default mailbox for aliases",
                                 selected: $viewModel.defaultMailbox,
                                 selections: viewModel.mailboxes,
                                 optional: false,
                                 shouldUpsell: false)
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
    let showMenu: Bool
    let setDefault: (Mailbox) -> Void
    let delete: (Mailbox) -> Void
    let verify: (Mailbox) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(mailBox.email)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    if isDefault {
                        Text("Default")
                            .font(.footnote)
                            .foregroundStyle(PassColor.interactionNormMinor1.toColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(PassColor.interactionNormMajor2.toColor)
                            .clipShape(Capsule())
                    }
                    Text(mailBox.verified ? "\(mailBox.aliasCount) aliases" : "Unverified mailbox")
                        .font(.footnote)
                        .foregroundStyle(PassColor.textWeak.toColor)
                }
            }

            Spacer()

            if showMenu, !isDefault {
                Menu(content: {
                    if !mailBox.isDefault {
                        if mailBox.verified {
                            Label(title: { Text("Make default") },
                                  icon: { Image(uiImage: IconProvider.star) })
                                .buttonEmbeded { setDefault(mailBox) }
                        } else {
                            Label(title: { Text("Verify") },
                                  icon: { Image(uiImage: IconProvider.star) })
                                .buttonEmbeded { verify(mailBox) }
                        }

                        Divider()
                    }
                    Label(title: { Text("Delete") },
                          icon: { Image(uiImage: IconProvider.trash) })
                        .buttonEmbeded { delete(mailBox) }
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.textWeak,
                                 backgroundColor: .clear,
                                 accessibilityLabel: "Mailbox action menu")
                })
            }
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
        ToolbarItem(placement: .topBarLeading) {
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
    var subtitle: String? { get }
}

extension Mailbox: TitleRepresentable {
    var title: String {
        email
    }

    var subtitle: String? {
        nil
    }
}

extension Domain: TitleRepresentable {
    var title: String {
        domain
    }

    var subtitle: String? {
        if isCustom {
            #localized("Your domain")
        } else if isPremium {
            #localized("Premium domain")
        } else {
            #localized("Public domain")
        }
    }
}

private struct GenericSelectionView<Selection: Identifiable & Equatable & TitleRepresentable>: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    @Binding var selected: Selection?
    let selections: [Selection]
    let optional: Bool
    let shouldUpsell: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: DesignConstant.sectionPadding) {
                    if optional {
                        row(title: #localized("Not selected"),
                            subtitle: nil,
                            isSelected: selected == nil,
                            action: { selected = nil })

                        PassDivider()
                    }

                    ForEach(selections) { element in
                        row(title: element.title,
                            subtitle: element.subtitle,
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

    func row(title: String, subtitle: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            VStack {
                Text(title)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let subtitle {
                    Text(subtitle)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()

            if isSelected {
                Image(uiImage: IconProvider.checkmark)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(PassColor.interactionNorm.toColor)
                    .frame(maxHeight: 25)
            }

            if shouldUpsell {
                Image(uiImage: PassIcon.passSubscriptionUnlimited)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
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
    private let mailbox: Mailbox
    private let otherMailboxes: [Mailbox]
    private let delete: (Mailbox, Int?) -> Void
    @State private var wantToTransferAliases = true
    @State private var selectedTransferMailbox: Mailbox?

    init(mailbox: Mailbox, otherMailboxes: [Mailbox], delete: @escaping (Mailbox, Int?) -> Void) {
        self.mailbox = mailbox
        self.otherMailboxes = otherMailboxes
        self.delete = delete
        _selectedTransferMailbox = .init(initialValue: otherMailboxes.first)
    }

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            VStack(spacing: DesignConstant.sectionPadding) {
                Text("Delete mailbox")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.semibold)

                // swiftlint:disable:next line_length
                Text("All aliases using the mailbox **\(mailbox.email)** will be also deleted. To keep receiving emails transfer these aliases to a different mailbox:")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                if !otherMailboxes.isEmpty {
                    Toggle(isOn: $wantToTransferAliases) {
                        Text("Transfer aliases")
                            .foregroundStyle(PassColor.textNorm.toColor)
                    }
                    .toggleStyle(SwitchToggleStyle.pass)

                    Group {
                        Divider()
                        HStack {
                            Text("To mailbox")
                                .foregroundStyle(PassColor.textNorm.toColor)

                            Spacer()

                            Picker("Mailbox", selection: $selectedTransferMailbox) {
                                ForEach(otherMailboxes) { mailbox in
                                    Text(mailbox.email)
                                        .tag(mailbox)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(4)
                            .tint(PassColor.textNorm.toColor)
                            .background(PassColor.interactionNormMinor1.toColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }.hidden(!wantToTransferAliases)
                }
            }

            Spacer()

            CapsuleTextButton(title: wantToTransferAliases ? #localized("Transfer and delete mailbox") :
                #localized("Delete mailbox"),
                titleColor: PassColor.interactionNormMinor1,
                backgroundColor: PassColor.signalDanger,
                height: 48,
                action: {
                    if wantToTransferAliases, let transferId = selectedTransferMailbox?.mailboxID {
                        delete(mailbox, transferId)
                    } else {
                        delete(mailbox, nil)
                    }
                    dismiss()
                })

            CapsuleTextButton(title: #localized("Cancel"),
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              height: 48,
                              action: { dismiss() })
        }
        .animation(.default, value: wantToTransferAliases)
        .padding(24)
        .background(PassColor.backgroundWeak.toColor)
    }
}
