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

    init(viewModel: LogInDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                usernameSection
                passwordSection
                    .padding(.vertical)
                urlsSection
                noteSection
                    .padding(.vertical)
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: viewModel.goBack) {
                Image(uiImage: IconProvider.chevronLeft)
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.name)
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            switch viewModel.itemContent.state {
            case .active:
                Button(action: viewModel.edit) {
                    Text("Edit")
                        .foregroundColor(.interactionNorm)
                }

            case .trashed:
                Button(action: viewModel.restore) {
                    Text("Restore")
                        .foregroundColor(.interactionNorm)
                }
            }
        }
    }

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .sectionTitleText()

            if viewModel.username.isEmpty {
                Text("No username")
                    .placeholderText()
            } else {
                Text(viewModel.username)
                    .sectionContentText()
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding()
        .roundedDetail()
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding()
        .roundedDetail()
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
