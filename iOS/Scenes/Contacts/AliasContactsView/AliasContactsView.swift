//
//
// AliasContactsView.swift
// Proton Pass - Created on 03/10/2024.
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

import Client
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

private enum AliasContactsSheetState {
    case explanation
    case creation
}

struct AliasContactsView: View {
    @StateObject var viewModel: AliasContactsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var sheetState: AliasContactsSheetState?

    var body: some View {
        mainContainer
            .onChange(of: viewModel.showExplanation) { value in
                guard value else {
                    return
                }
                sheetState = .explanation
            }
            .optionalSheet(binding: $sheetState) { state in
                sheetContent(for: state)
                    .presentationDetents(presentationDetents(for: state))
            }
    }
}

private extension AliasContactsView {
    var mainContainer: some View {
        List {
            VStack(spacing: DesignConstant.sectionPadding) {
                mainTitle
                    .padding(.top)
                // swiftlint:disable:next line_length
                Text("A contact is created for every email address that sends emails to or receives emails from \(viewModel.alias.email)")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .padding(.bottom, viewModel.aliasName.isEmpty ? DesignConstant.sectionPadding : 0)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if viewModel.hasNoContact {
                AliasContactsEmptyView { sheetState = .explanation }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                contactList
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain) // Use plain list style for minimal look
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.aliasName)
        .animation(.default, value: viewModel.hasNoContact)
        .animation(.default, value: viewModel.contactsInfos)
        .toolbar { toolbarContent }
        .showSpinner(viewModel.loading)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PassColor.backgroundNorm.toColor, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    var mainTitle: some View {
        Label(title: {
            Text("Contacts")
                .font(.title.bold())
                .foregroundStyle(PassColor.textNorm.toColor)
        }, icon: {
            Button(action: { sheetState = .explanation }, label: {
                Text("?")
                    .fontWeight(.medium)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 11)
                    .foregroundStyle(PassColor.aliasInteractionNormMajor2.toColor)
                    .background(PassColor.aliasInteractionNormMinor1.toColor)
                    .clipShape(Capsule())
            })
            .buttonStyle(.plain)
        })
        .labelStyle(.rightIcon)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension AliasContactsView {
    @ViewBuilder
    var contactList: some View {
        if !viewModel.contactsInfos.activeContacts.isEmpty {
            Section {
                ForEach(viewModel.contactsInfos.activeContacts) { contact in
                    ContactRow(contact: contact,
                               onSend: { viewModel.openMail(emailTo: contact.reverseAlias) },
                               onCopyAddress: { viewModel.copyContact(contact) },
                               onToggleState: { viewModel.toggleContactState(contact) },
                               onDelete: { viewModel.delete(contact: contact) })
                        .onAppear {
                            if contact == viewModel.contactsInfos.activeContacts.last {
                                viewModel.loadMore()
                            }
                        }
                }

                if viewModel.loadingMoreContent {
                    AliasContactsSkeletonView()
                }
            }.listRowInsets(.init(top: 13,
                                  leading: 0,
                                  bottom: 0,
                                  trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }

        if !viewModel.contactsInfos.blockContacts.isEmpty {
            Section {
                ForEach(viewModel.contactsInfos.blockContacts) { contact in
                    ContactRow(contact: contact,
                               onSend: { viewModel.openMail(emailTo: contact.reverseAlias) },
                               onCopyAddress: { viewModel.copyContact(contact) },
                               onToggleState: { viewModel.toggleContactState(contact) },
                               onDelete: { viewModel.delete(contact: contact) })
                }
                .listRowInsets(.init(top: 13,
                                     leading: 0,
                                     bottom: 0,
                                     trailing: 0))
            } header: {
                Text("Blocked addresses")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
}

private extension AliasContactsView {
    @ViewBuilder
    func sheetContent(for state: AliasContactsSheetState) -> some View {
        switch state {
        case .creation:
            CreateContactView(viewModel: .init(itemIds: viewModel.itemIds))
        case .explanation:
            AliasExplanationView(email: viewModel.displayName)
        }
    }

    func presentationDetents(for state: AliasContactsSheetState) -> Set<PresentationDetent> {
        switch state {
        case .creation:
            [.large]
        case .explanation:
            [.medium, .large]
        }
    }
}

private extension AliasContactsView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.aliasInteractionNormMajor2,
                         backgroundColor: PassColor.aliasInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                CapsuleTextButton(title: #localized("Create contact"),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.aliasInteractionNormMajor1,
                                  action: {
                                      if viewModel.canManageAliases {
                                          sheetState = .creation
                                      } else {
                                          viewModel.upsell()
                                      }
                                  })
                                  .padding(.vertical, 8)
                if !viewModel.canManageAliases {
                    passPlusBadge
                }
            }
        }
    }

    var passPlusBadge: some View {
        Image(uiImage: PassIcon.passSubscriptionBadge)
            .resizable()
            .scaledToFit()
            .frame(height: 24)
    }
}
