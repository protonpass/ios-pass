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
    @State private var bottomId = UUID().uuidString
    private let tintColor = UIColor.notificationSuccess

    init(viewModel: AliasDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 0) {
                    ItemDetailTitleView(color: tintColor,
                                        icon: .image(IconProvider.alias),
                                        title: viewModel.name)
                    .padding(.bottom, 24)

                    aliasMailboxesSection
                        .padding(.bottom, 8)

                    NoteSection(note: viewModel.note, tintColor: tintColor)

                    ItemDetailMoreInfoSection(itemContent: viewModel.itemContent,
                                              onExpand: { withAnimation { value.scrollTo(bottomId) } })
                    .padding(.top, 24)
                    .id(bottomId)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: UIDevice.current.isIpad ? IconProvider.chevronLeft : IconProvider.chevronDown,
                         color: tintColor,
                         action: viewModel.goBack)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            switch viewModel.itemContent.item.itemState {
            case .active:
                HStack(spacing: 0) {
                    CapsuleTitledButton(icon: IconProvider.pencil,
                                        title: "Edit",
                                        color: tintColor,
                                        action: viewModel.edit)

                    Menu(content: {
                        Button(action: {
                            print("Pin")
                        }, label: {
                            Label(title: {
                                Text("Pin")
                            }, icon: {
                                Image(uiImage: IconProvider.bookmark)
                            })
                        })

                        DestructiveButton(title: "Move to trash",
                                          icon: IconProvider.trash,
                                          action: { print("Trash") })
                    }, label: {
                        CapsuleButton(icon: IconProvider.threeDotsVertical,
                                      color: tintColor,
                                      action: {})
                    })
                }

            case .trashed:
                Button(action: viewModel.restore) {
                    Text("Restore")
                        .foregroundColor(.interactionNorm)
                }
            }
        }
    }

    private var aliasMailboxesSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            aliasRow
            Divider()
            mailboxesRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedDetail()
        .animation(.default, value: viewModel.mailboxes)
    }

    private var aliasRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user,
                                  color: tintColor.withAlphaComponent(0.5))

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

    private var mailboxesRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.forward,
                                  color: tintColor.withAlphaComponent(0.5))

            VStack(alignment: .leading, spacing: 8) {
                Text("Forwarded to")
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
                    AnimatingGrayGradient()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    AnimatingGrayGradient()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    AnimatingGrayGradient()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.mailboxes)
    }
}
