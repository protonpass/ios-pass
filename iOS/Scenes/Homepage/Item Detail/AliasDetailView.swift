//
// AliasDetailView.swift
// Proton Pass - Created on 15/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct AliasDetailView: View {
    @StateObject private var viewModel: AliasDetailViewModel
    @Namespace private var bottomID

    private var iconTintColor: UIColor { viewModel.itemContent.type.normColor }

    init(viewModel: AliasDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if viewModel.isShownAsSheet {
            NavigationView {
                realBody
            }
            .navigationViewStyle(.stack)
        } else {
            realBody
        }
    }

    private var realBody: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 0) {
                    ItemDetailTitleView(itemContent: viewModel.itemContent,
                                        vault: viewModel.vault,
                                        favIconRepository: viewModel.favIconRepository)
                        .padding(.bottom, 24)

                    aliasMailboxesSection
                        .padding(.bottom, 8)

                    if !viewModel.itemContent.note.isEmpty {
                        NoteDetailSection(itemContent: viewModel.itemContent,
                                          vault: viewModel.vault,
                                          theme: viewModel.theme,
                                          favIconRepository: viewModel.favIconRepository)
                    }

                    ItemDetailMoreInfoSection(
                        itemContent: viewModel.itemContent,
                        onExpand: { withAnimation { value.scrollTo(bottomID, anchor: .bottom) } })
                    .padding(.top, 24)
                    .id(bottomID)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .onFirstAppear(perform: viewModel.getAlias)
        .itemDetailBackground(theme: viewModel.theme)
        .toolbar {
            ItemDetailToolbar(isShownAsSheet: viewModel.isShownAsSheet,
                              itemContent: viewModel.itemContent,
                              onGoBack: viewModel.goBack,
                              onEdit: viewModel.edit,
                              onMoveToAnotherVault: viewModel.moveToAnotherVault,
                              onMoveToTrash: viewModel.moveToTrash,
                              onRestore: viewModel.restore,
                              onPermanentlyDelete: viewModel.permanentlyDelete)
        }
    }

    private var aliasMailboxesSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            aliasRow
            PassSectionDivider()
            mailboxesRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedDetailSection()
        .animation(.default, value: viewModel.mailboxes)
    }

    private var aliasRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: iconTintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()

                if viewModel.aliasEmail.isEmpty {
                    Text("No username")
                        .placeholderText()
                } else {
                    Text(viewModel.aliasEmail)
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.copyAliasEmail)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .contextMenu {
            Button(action: viewModel.copyAliasEmail) {
                Text("Copy")
            }

            Button(action: {
                viewModel.showLarge(viewModel.aliasEmail)
            }, label: {
                Text("Show large")
            })
        }
    }

    @ViewBuilder
    private var mailboxesRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.forward, color: iconTintColor)

            VStack(alignment: .leading, spacing: 8) {
                Text("Forwarding to")
                    .sectionTitleText()

                if let mailboxes = viewModel.mailboxes {
                    ForEach(mailboxes, id: \.ID) { mailbox in
                        Text(mailbox.email)
                            .sectionContentText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button(action: {
                                    viewModel.copyMailboxEmail(mailbox.email)
                                }, label: {
                                    Text("Copy")
                                })

                                Button(action: {
                                    viewModel.showLarge(mailbox.email)
                                }, label: {
                                    Text("Show large")
                                })
                            }
                    }
                } else {
                    Group {
                        AnimatingGradient(tintColor: iconTintColor)
                        AnimatingGradient(tintColor: iconTintColor)
                        AnimatingGradient(tintColor: iconTintColor)
                    }
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.mailboxes)
    }
}
