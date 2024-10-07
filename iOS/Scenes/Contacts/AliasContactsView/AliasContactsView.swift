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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
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
            .navigationStackEmbeded()
            .onChange(of: viewModel.showExplanation) { value in
                guard value else {
                    return
                }
                sheetState = .explanation
            }
            .optionalSheet(binding: $sheetState) { state in
                sheetContent(for: state)
                    .presentationDetents(presentationDetents(for: state))
                    .presentationDragIndicator(.visible)
            }
    }
}

private extension AliasContactsView {
    var mainContainer: some View {
        VStack {
            mainTitle
                .padding(.top)

            // TODO: alias name element

//            if viewModel.hasNoContact {
//                AliasContactsEmptyView { sheetState = .explanation }
//            } else {
            contactList
//            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
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
    var contactList: some View {
        LazyVStack(spacing: 25) {
            if !viewModel.contactsInfos.activeContacts.isEmpty {
                Section {
                    ForEach(viewModel.contactsInfos.activeContacts) { contact in
                        itemRow(for: contact)
                    }
                } header: {
                    Text("Forwarding addresses")
                        .font(.callout)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !viewModel.contactsInfos.blockContacts.isEmpty {
                Section {
                    ForEach(viewModel.contactsInfos.blockContacts) { contact in
                        itemRow(for: contact)
                    }
                } header: {
                    Text("Blocked")
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    func itemRow(for contact: AliasContact) -> some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding) {
            HStack {
                Text(verbatim: contact.email)
                    .foregroundStyle(PassColor.textNorm.toColor)

                Spacer()

                if !contact.blocked {
                    Button {
                        viewModel.openMail(emailTo: contact.email)
                    } label: {
                        Image(uiImage: IconProvider.paperPlane)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    }
                    .padding(.trailing, DesignConstant.sectionPadding)
                }

                Menu(content: {
                    if !contact.blocked {
                        Label(title: { Text("Send email") }, icon: { Image(uiImage: IconProvider.paperPlane) })
                            .buttonEmbeded {
                                viewModel.openMail(emailTo: contact.email)
                            }
                    }

                    Label(title: { Text("Copy address") }, icon: { Image(uiImage: IconProvider.squares) })
                        .buttonEmbeded {
                            viewModel.copyContact(contact)
                        }

                    Divider()

                    Label(title: { Text(contact.actionTitle) },
                          icon: { Image(uiImage: IconProvider.crossCircle) })
                        .buttonEmbeded {
                            viewModel.toggleContactState(contact)
                        }

                    Label(title: { Text("Delete") },
                          icon: { Image(uiImage: IconProvider.trash) })
                        .buttonEmbeded {
                            viewModel.delete(contact: contact)
                        }
                }, label: {
                    IconProvider.threeDotsVertical
                        .foregroundStyle(PassColor.textWeak.toColor)
                })
            }

            VStack(alignment: .leading) {
                Text("No Activity in the last 14 days.")
                Text("Contact created 3 months ago.")
                Text("0 forwarded, 0 sent in the last 14 days.")
            }
            .font(.footnote)
            .foregroundStyle(PassColor.textWeak.toColor)

            Text(contact.actionTitle)
                .font(.callout)
                .foregroundStyle(PassColor.aliasInteractionNormMajor2.toColor)
                .frame(height: 40)
                .padding(.horizontal, 16)
                .background(contact.blocked ? .clear : PassColor.aliasInteractionNormMinor1.toColor)
                .clipShape(Capsule())
                .buttonEmbeded {
                    sheetState = .creation
                }
                .overlay(Capsule()
                    .stroke(PassColor.aliasInteractionNormMinor1.toColor, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(DesignConstant.sectionPadding)
        .background(PassColor.inputBorderNorm.toColor)
        .cornerRadius(16)
    }
}

extension AliasContact {
    var actionTitle: String {
        blocked ? #localized("Unblock contact") : #localized("Block contact")
    }
}

private extension AliasContactsView {
    @ViewBuilder
    func sheetContent(for state: AliasContactsSheetState) -> some View {
        switch state {
        case .creation:
            CreateContactView(viewModel: .init(itemIds: viewModel.itemIds))
        case .explanation:
            Text("explanation")
        }
    }

    func presentationDetents(for state: AliasContactsSheetState) -> Set<PresentationDetent> {
        //        let customHeight: CGFloat = switch state {
        //        case .domain:
        //            // +1 for "Not selected" option
        //            OptionRowHeight.compact.value * CGFloat(viewModel.domains.count + 1) + 50
        //        case .mailbox:
        //            OptionRowHeight.compact.value * CGFloat(viewModel.mailboxes.count) + 50
        //        case .vault:
        //            OptionRowHeight.medium.value * CGFloat(viewModel.vaults.count) + 50
        //        }
        //        return [.height(customHeight), .large]
        //    }
        [ /* .height(customHeight), */ .large]
    }
}

private extension AliasContactsView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.aliasInteractionNormMajor2,
                         backgroundColor: PassColor.aliasInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CapsuleTextButton(title: #localized("Create contact"),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.aliasInteractionNormMajor1,
                              action: { sheetState = .creation })
                .padding(.vertical, 8)
        }
    }
}

struct AliasContactsEmptyView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            Spacer()

            Image(uiImage: PassIcon.stamp)

            VStack(spacing: 8) {
                Text("Alias contacts")
                    .font(.headline)
                    .foregroundStyle(PassColor.textNorm.toColor)

                Text("To keep your personal email address hidden, you can create an alias contact that masks your address.")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.footnote)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .padding(.horizontal, 40)

            CapsuleTextButton(title: #localized("Learn more"),
                              titleColor: PassColor.aliasInteractionNormMajor2,
                              backgroundColor: PassColor.aliasInteractionNormMinor1,
                              action: action)
            Spacer()
        }
    }
}
