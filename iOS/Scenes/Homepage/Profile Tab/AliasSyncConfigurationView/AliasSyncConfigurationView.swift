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

import Screens
import SwiftUI

public enum AliasSyncConfigurationSheetState {
    case domain
    case mailbox
    case vault

//    public var height: CGFloat {
//        switch self {
//        case let .mailbox(mailboxSelection, _):
//            OptionRowHeight.compact.value * CGFloat(mailboxSelection.wrappedValue.allUserMailboxes.count) + 150
//        case .suffix:
//            280
//        }
//    }
}

struct AliasSyncConfigurationView: View {
    @StateObject private var viewModel = AliasSyncConfigurationViewModel()
    @Environment(\.dismiss) private var dismiss
//    @State private var showVaultSelectionSheet = false

    @State private var sheetState: AliasSyncConfigurationSheetState?

    var body: some View {
        VStack(alignment: .leading) {
            Section {
                SynchroElementRow(title: viewModel.defaultDomain?.domain ?? "",
                                  subtitle: "domain") {
                    sheetState = .domain
                }
            } header: {
                Text("Domain")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.bold)
            }

            Section {
                SynchroElementRow(title: viewModel.defaultMailbox?.email ?? "",
                                  subtitle: "mailbox") {
                    sheetState = .mailbox
                }

            } header: {
                Text("Mailboxes")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.bold)
            }

            Section {
                if let userSyncData = viewModel.userAliasSyncData,
                   !userSyncData.aliasSyncEnabled {
                    AliasSyncExplanationView(missingAliases: userSyncData.pendingAliasToSync,
                                             closeAction: nil) {
                        viewModel.showSimpleLoginAliasesActivation()
                    }
                } else {
                    SelectedSyncVaultRow(vault: viewModel.selectedVault?.vault) {
                        sheetState = .vault
//                        showVaultSelectionSheet.toggle()
                    }
                }
            } header: {
                Text("SimpleLogin sync")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.bold)
            }
//            Button(action: {
//                showVaultSelectionSheet.toggle()
//            }, label: {
//                selectedVault(vault: viewModel.selectedVault?.vault)
//                    .padding(.horizontal)
//            })
//            .buttonStyle(.plain)
//            .roundedEditableSection()
//            .padding(.bottom, 10)
//
//            Text("SimpleLogin aliases will be imported into this vault.")
//                .font(.footnote)
//                .foregroundStyle(PassColor.textWeak.toColor)
//                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .navigationTitle("Aliases")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
//        .sheet(isPresented: $showVaultSelectionSheet) {
        ////            VaultSelectionView(selectedVault: $viewModel.selectedVault,
        ////                               vaults: viewModel.vaults)
//                .presentationDetents([.medium, .large])
//                .presentationDragIndicator(.visible)
//        }
        .optionalSheet(binding: $sheetState) { state in
            sheetContent(for: state)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }

        .showSpinner(viewModel.loading)
        .navigationStackEmbeded()
    }

    @ViewBuilder
    func sheetContent(for state: AliasSyncConfigurationSheetState) -> some View {
        switch state {
        case .domain:
            DomainSelectionView(selectedDomain: $viewModel.defaultDomain, domains: viewModel.domains)
        case .mailbox:
            Text("mailbox")
        case .vault:
            VaultSelectionView(selectedVault: $viewModel.selectedVault,
                               vaults: viewModel.vaults)
        }
    }
}

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

public struct SynchroElementRow: View {
    private let title: String
    private let subtitle: String
    let action: () -> Void

    public init(title: String,
                subtitle: String,
                action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    public var body: some View {
        Button(action:
            action,
            label: {
                selectedElement
                    .padding(.horizontal)
            })
            .buttonStyle(.plain)
            .roundedEditableSection()
            .padding(.bottom, 10)
    }

    private var selectedElement: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Default \(subtitle) for aliases")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)

                Text(title)
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
//        ToolbarItem(placement: .navigationBarTrailing) {
//            DisablableCapsuleTextButton(title: #localized("Confirm"),
//                                        titleColor: PassColor.textInvert,
//                                        disableTitleColor: PassColor.textHint,
//                                        backgroundColor: PassColor.interactionNormMajor1,
//                                        disableBackgroundColor: PassColor.interactionNormMinor1,
//                                        disabled: !viewModel.canActiveSync,
//                                        height: 44) {
//                Task {
//                    do {
//                        try await viewModel.activateSync()
//                        dismiss()
//                    } catch {
//                        return
//                    }
//                }
//            }
//        }
    }
}

struct AliasesView_Previews: PreviewProvider {
    static var previews: some View {
        AliasSyncConfigurationView()
    }
}

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

public struct DomainSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDomain: Domain?
    public let domains: [Domain]

    public init(selectedDomain: Binding<Domain?>, domains: [Domain]) {
        _selectedDomain = selectedDomain
        self.domains = domains
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(domains, id: \.domain) { domain in
                        let isSelected = domain == selectedDomain
                        Button(action: {
                            selectedDomain = domain
                            dismiss()
                        }, label: {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text(domain.domain)
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
            .animation(.default, value: selectedDomain)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Default domain for aliases")
                        .adaptiveForegroundStyle(PassColor.textNorm.toColor)
                }
            }
        }
    }
}

// TODO: faire une version generic
public struct MailboxSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMailbox: Mailbox?
    public let mailboxes: [Mailbox]

    public init(selectedMailbox: Binding<Mailbox?>, mailboxes: [Mailbox]) {
        _selectedMailbox = selectedMailbox
        self.mailboxes = mailboxes
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(mailboxes) { mailbox in
                        let isSelected = mailbox == selectedMailbox
                        Button(action: {
                            selectedMailbox = mailbox
                            dismiss()
                        }, label: {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text(mailbox.email)
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
                    }
                }
            }
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: selectedMailbox)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Default mailbox for aliases")
                        .adaptiveForegroundStyle(PassColor.textNorm.toColor)
                }
            }
        }
    }
}

//
// struct SimpleLoginAliasActivationView: View {
//    @StateObject private var viewModel = SimpleLoginAliasActivationViewModel()
//    @Environment(\.dismiss) private var dismiss
//    @State private var showVaultSelectionSheet = false
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Button(action: {
//                showVaultSelectionSheet.toggle()
//            }, label: {
//                SelectedSyncVaultRow(vault: viewModel.selectedVault?.vault)
//                    .padding(.horizontal)
//            })
//            .buttonStyle(.plain)
//            .roundedEditableSection()
//            .padding(.bottom, 10)
//
//            Text("SimpleLogin aliases will be imported into this vault.")
//                .font(.footnote)
//                .foregroundStyle(PassColor.textWeak.toColor)
//                .frame(maxWidth: .infinity, alignment: .center)
//        }
//        .animation(.default, value: viewModel.selectedVault)
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .navigationTitle("Sync Aliases")
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .toolbar { toolbarContent }
//        .scrollViewEmbeded(maxWidth: .infinity)
//        .background(PassColor.backgroundNorm.toColor)
//        .sheet(isPresented: $showVaultSelectionSheet) {
//            VaultSelectionView(selectedVault: $viewModel.selectedVault,
//                               vaults: viewModel.vaults)
//                .presentationDragIndicator(.visible)
//        }
//        .showSpinner(viewModel.loading)
//        .navigationStackEmbeded()
//    }
//
////    func selectedVault(vault: Vault?) -> some View {
////        HStack(spacing: 16) {
////            if let vault {
////                VaultThumbnail(vault: vault)
////            }
////
////            VStack(alignment: .leading) {
////                Text("Default SimpleLogin vault")
////                    .font(.callout)
////                    .foregroundStyle(PassColor.textWeak.toColor)
////
////                Text(vault?.name ?? "None")
////                    .foregroundStyle(PassColor.textNorm.toColor)
////            }
////            Spacer()
////
////            Image(uiImage: IconProvider.chevronRight)
////                .resizable()
////                .scaledToFit()
////                .foregroundStyle(PassColor.textWeak.toColor)
////                .frame(maxHeight: 20)
////        }
////        .frame(maxWidth: .infinity)
////        .frame(height: 70)
////        .contentShape(.rect)
////    }
// }
//
// private extension SimpleLoginAliasActivationView {
//    @ToolbarContentBuilder
//    var toolbarContent: some ToolbarContent {
//        ToolbarItem(placement: .navigationBarLeading) {
//            CircleButton(icon: IconProvider.cross,
//                         iconColor: PassColor.interactionNormMajor1,
//                         backgroundColor: PassColor.interactionNormMinor1,
//                         accessibilityLabel: "Close") {
//                dismiss()
//            }
//        }
//        ToolbarItem(placement: .navigationBarTrailing) {
//            DisablableCapsuleTextButton(title: #localized("Confirm"),
//                                        titleColor: PassColor.textInvert,
//                                        disableTitleColor: PassColor.textHint,
//                                        backgroundColor: PassColor.interactionNormMajor1,
//                                        disableBackgroundColor: PassColor.interactionNormMinor1,
//                                        disabled: !viewModel.canActiveSync,
//                                        height: 44) {
//                Task {
//                    do {
//                        try await viewModel.activateSync()
//                        dismiss()
//                    } catch {
//                        return
//                    }
//                }
//            }
//        }
//    }
// }
//
// struct SimpleLoginAliasActivationView_Previews: PreviewProvider {
//    static var previews: some View {
//        SimpleLoginAliasActivationView()
//    }
// }
