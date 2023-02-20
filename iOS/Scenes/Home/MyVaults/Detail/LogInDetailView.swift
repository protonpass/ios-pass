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

import Core
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct LogInDetailView: View {
    @StateObject private var viewModel: LogInDetailViewModel
    @State private var isShowingPassword = false
    @State private var bottomId = UUID().uuidString

    init(viewModel: LogInDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 0) {
                    ItemDetailTitleView(itemContent: viewModel.itemContent)
                        .padding(.bottom, 24)

                    usernamePassword2FaSection
                    urlsSection
                        .padding(.vertical, 8)
                    NoteDetailSection(itemContent: viewModel.itemContent)

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
        .toolbar {
            ItemDetailToolbar(itemContent: viewModel.itemContent,
                              onGoBack: viewModel.goBack,
                              onEdit: viewModel.edit,
                              onRevealMoreOptions: {})
        }
    }

    private var usernamePassword2FaSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            usernameRow
            Divider()
            passwordRow

            switch viewModel.totpManager.state {
            case .empty:
                EmptyView()
            default:
                Divider()
                totpRow
            }
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedDetailSection()
    }

    private var usernameRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user,
                                  color: viewModel.itemContent.tintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()

                if viewModel.username.isEmpty {
                    Text("No username")
                        .placeholderText()
                } else {
                    Text(viewModel.username)
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.copyUsername)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
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

    private var passwordRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.key,
                                  color: viewModel.itemContent.tintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Password")
                    .sectionTitleText()

                if isShowingPassword {
                    Text(viewModel.password)
                        .sectionContentText()
                } else {
                    Text(String(repeating: "•", count: 20))
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.copyPassword)

            Spacer()

            CircleButton(icon: isShowingPassword ? IconProvider.eyeSlash : IconProvider.eye,
                         color: viewModel.itemContent.tintColor,
                         action: { isShowingPassword.toggle() })
            .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: isShowingPassword)
        .contextMenu {
            Button(action: {
                withAnimation {
                    isShowingPassword.toggle()
                }
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
    }

    @ViewBuilder
    private var totpRow: some View {
        if case .empty = viewModel.totpManager.state {
            EmptyView()
        } else {
            HStack(spacing: kItemDetailSectionPadding) {
                ItemDetailSectionIcon(icon: IconProvider.lock,
                                      color: viewModel.itemContent.tintColor)

                VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                    Text("Two Factor Authentication")
                        .sectionTitleText()

                    switch viewModel.totpManager.state {
                    case .empty:
                        EmptyView()
                    case .loading:
                        ProgressView()
                    case .valid(let data):
                        TOTPText(code: data.code)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .invalid:
                        Text("Invalid Two Factor Authentication URI")
                            .placeholderText()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: viewModel.copyTotpCode)

                switch viewModel.totpManager.state {
                case .valid(let data):
                    TOTPCircularTimer(data: data.timerData)
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, kItemDetailSectionPadding)
            .animation(.default, value: viewModel.totpManager.state)
        }
    }

    private var urlsSection: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth,
                                  color: viewModel.itemContent.tintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Website")
                    .sectionTitleText()

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
        }
        .padding(kItemDetailSectionPadding)
        .roundedDetailSection()
    }
}
