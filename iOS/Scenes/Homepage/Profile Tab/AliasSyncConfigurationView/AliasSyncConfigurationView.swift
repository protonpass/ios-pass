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
import ProtonCoreUIFoundations
import Screens
import SwiftUI
import Macro

enum AliasSyncConfigurationSheetState {
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
                    }
                }
            } header: {
                Text("SimpleLogin sync")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.bold)
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
    func sheetContent(for state: AliasSyncConfigurationSheetState) -> some View {
        switch state {
        case .domain:
            GenericSelectionView(title: "domain", selected: $viewModel.defaultDomain, selections: viewModel.domains)
        case .mailbox:
            GenericSelectionView(title: "mailbox", selected: $viewModel.defaultMailbox, selections: viewModel.mailboxes)
        case .vault:
            VaultSelectionView(selectedVault: $viewModel.selectedVault,
                               vaults: viewModel.vaults)
        }
    }
}


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
    }
}

struct AliasesView_Previews: PreviewProvider {
    static var previews: some View {
        AliasSyncConfigurationView()
    }
}




//public struct DomainSelectionView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Binding var selectedDomain: Domain?
//    public let domains: [Domain]
//
//    public init(selectedDomain: Binding<Domain?>, domains: [Domain]) {
//        _selectedDomain = selectedDomain
//        self.domains = domains
//    }
//
//    public var body: some View {
//        NavigationStack {
//            ScrollView {
//                LazyVStack(spacing: 0) {
//                    ForEach(domains, id: \.domain) { domain in
//                        let isSelected = domain == selectedDomain
//                        Button(action: {
//                            selectedDomain = domain
//                            dismiss()
//                        }, label: {
//                            HStack(spacing: 16) {
//                                VStack(alignment: .leading) {
//                                    Text(domain.domain)
//                                        .foregroundStyle(PassColor.textNorm.toColor)
//                                }
//
//                                Spacer()
//
//                                if isSelected {
//                                    Image(uiImage: IconProvider.checkmark)
//                                        .resizable()
//                                        .scaledToFit()
//                                        .foregroundStyle(PassColor.interactionNorm.toColor)
//                                        .frame(maxHeight: 20)
//                                }
//                            }
//                            .frame(maxWidth: .infinity)
//                            .frame(height: 70)
//                            .contentShape(.rect)
//                            .animation(.default, value: isSelected)
//                        })
//                        .buttonStyle(.plain)
//                        .padding(.horizontal)
//                    }
//                }
//            }
//            .background(PassColor.backgroundWeak.toColor)
//            .navigationBarTitleDisplayMode(.inline)
//            .animation(.default, value: selectedDomain)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Default domain for aliases")
//                        .adaptiveForegroundStyle(PassColor.textNorm.toColor)
//                }
//            }
//        }
//    }
//}
//
//// TODO: faire une version generic
//public struct MailboxSelectionView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Binding var selectedMailbox: MailboxSettings?
//    public let mailboxes: [MailboxSettings]
//    
//
//    public init(selectedMailbox: Binding<MailboxSettings?>, mailboxes: [MailboxSettings]) {
//        _selectedMailbox = selectedMailbox
//        self.mailboxes = mailboxes
//    }
//
//    public var body: some View {
//        NavigationStack {
//            ScrollView {
//                LazyVStack(spacing: 0) {
//                    ForEach(mailboxes) { mailbox in
//                        let isSelected = mailbox == selectedMailbox
//                        Button(action: {
//                            selectedMailbox = mailbox
//                            dismiss()
//                        }, label: {
//                            HStack(spacing: 16) {
//                                VStack(alignment: .leading) {
//                                    Text(mailbox.email)
//                                        .foregroundStyle(PassColor.textNorm.toColor)
//                                }
//
//                                Spacer()
//
//                                if isSelected {
//                                    Image(uiImage: IconProvider.checkmark)
//                                        .resizable()
//                                        .scaledToFit()
//                                        .foregroundStyle(PassColor.interactionNorm.toColor)
//                                        .frame(maxHeight: 20)
//                                }
//                            }
//                            .frame(maxWidth: .infinity)
//                            .frame(height: 70)
//                            .contentShape(.rect)
//                            .animation(.default, value: isSelected)
//                        })
//                        .buttonStyle(.plain)
//                        .padding(.horizontal)
//                    }
//                }
//            }
//            .background(PassColor.backgroundWeak.toColor)
//            .navigationBarTitleDisplayMode(.inline)
//            .animation(.default, value: selectedMailbox)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Default mailbox for aliases")
//                        .adaptiveForegroundStyle(PassColor.textNorm.toColor)
//                }
//            }
//        }
//    }
//}

protocol TitleRepresentable {
    var title: String { get }
}

extension MailboxSettings: TitleRepresentable {
    var title: String {
        email
    }
}

extension Domain: TitleRepresentable {
    var title: String {
        domain
    }
}

struct GenericSelectionView<Selection: Identifiable & Equatable & TitleRepresentable>: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: Selection?
    let selections: [Selection]
    let title: String
    
    init(title: String, selected: Binding<Selection?>, selections: [Selection]) {
        _selected = selected
        self.selections = selections
        self.title = title
    }

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
                    Text("Default \(title) for aliases")
                        .adaptiveForegroundStyle(PassColor.textNorm.toColor)
                }
            }
        }
    }
}
