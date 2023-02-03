//
// LogInDetailView.swift
// Proton Pass - Created on 07/09/2022.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct LogInDetailView: View {
    @StateObject private var viewModel: LogInDetailViewModel
    @State private var isShowingPassword = false
    private let tintColor = UIColor.brandNorm

    init(viewModel: LogInDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ItemDetailTitleView(color: tintColor,
                                    icon: .initials(String(viewModel.name.prefix(2))),
                                    title: viewModel.name)

                usernamePassword2FaSection

                ItemDetailFooterView(createTime: viewModel.createTime,
                                     modifyTime: viewModel.modifyTime)
            }
            .padding()
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

    private var usernamePassword2FaSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            usernameRow
            Divider()
            passwordRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedDetail()
    }

    private var usernameRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user,
                                  color: tintColor.withAlphaComponent(0.5))

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()

                if viewModel.username.isEmpty {
                    Text("No username")
                        .placeholderText()
                } else {
                    Text(viewModel.username)
                        .sectionContentText()
                        .contentShape(Rectangle())
                        .onTapGesture(perform: viewModel.copyUsername)
                        .contextMenu {
                            Button(action: viewModel.copyUsername) {
                                Text("Copy")
                            }

                            Button(action: {
                                viewModel.showLarge(viewModel.username)
                            }, label: {
                                Text("Show large")
                            })
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
    }

    private var passwordRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.keySkeleton,
                                  color: tintColor.withAlphaComponent(0.5))

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Password")
                    .sectionTitleText()

                Text(isShowingPassword ?
                     viewModel.password : String(repeating: "•", count: viewModel.password.count))
                .sectionContentText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: viewModel.copyPassword)
                .contextMenu {
                    Button(action: {
                        isShowingPassword.toggle()
                    }, label: {
                        Text(isShowingPassword ? "Conceal" : "Reveal")
                    })

                    Button(action: viewModel.copyPassword) {
                        Text("Copy")
                    }

                    Button(action: viewModel.showLargePassword) {
                        Text("Show large")
                    }
                }
                .transaction { transaction in
                    transaction.animation = .default
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            CapsuleButton(icon: isShowingPassword ? IconProvider.eyeSlash : IconProvider.eye,
                          color: tintColor,
                          action: { isShowingPassword.toggle() })
            .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: isShowingPassword)
    }

    @ViewBuilder
    private var totpSection: some View {
        if case .empty = viewModel.totpManager.state {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Two Factor Authentication")
                    .sectionTitleText()

                switch viewModel.totpManager.state {
                case .empty, .loading:
                    EmptyView()
                case .valid(let data):
                    HStack {
                        Text(data.code)
                        Spacer()
                        TOTPCircularTimer(data: data.timerData)
                            .frame(width: 22, height: 22)
                    }
                case .invalid:
                    Text("Invalid Two Factor Authentication URI.")
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.copyTotpCode)
            .roundedDetail()
        }
    }

    private var urlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Websites")

            if viewModel.urls.isEmpty {
                Text("No websites")
                    .placeholderText()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.urls, id: \.self) { url in
                        Button(action: {
                            viewModel.openUrl(url)
                        }, label: {
                            Text(url)
                                .foregroundColor(.interactionNorm)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        })
                        .contextMenu {
                            Button(action: {
                                viewModel.openUrl(url)
                            }, label: {
                                Text("Open")
                            })

                            Button(action: {
                                viewModel.copyToClipboard(text: url, message: "Website copied")
                            }, label: {
                                Text("Copy")
                            })
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.default, value: viewModel.urls)
        .padding(.horizontal)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note")
            if viewModel.note.isEmpty {
                Text("Empty note")
                    .placeholderText()
            } else {
                Text(viewModel.note)
                    .sectionContentText()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}
