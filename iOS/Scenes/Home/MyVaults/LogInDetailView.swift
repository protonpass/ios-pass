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
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: LogInDetailViewModel
    @State private var isShowingPassword = false

    init(viewModel: LogInDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 32) {
            usernameSection
            urlsSection
            passwordSection
            noteSection
            Spacer()
        }
        .padding()
        .toolbar(content: toolbarContent)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
//        ToolbarItem(placement: .navigationBarLeading) {
//            Button(action: {
//                presentationMode.wrappedValue.dismiss()
//            }, label: {
//                Image(uiImage: IconProvider.chevronLeft)
//                    .foregroundColor(.primary)
//            })
//        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.name)
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            trailingMenu
        }
    }

    private var trailingMenu: some View {
        Menu(content: {
            Button(action: {
                print("Edit")
            }, label: {
                Label(title: {
                    Text("Edit login")
                }, icon: {
                    Image(uiImage: IconProvider.eraser)
                })
            })

            Divider()

            DestructiveButton(title: "Move to trash",
                              icon: IconProvider.trash,
                              action: {
                print("Delete")
            })
        }, label: {
            Image(uiImage: IconProvider.threeDotsHorizontal)
                .foregroundColor(.primary)
        })
    }

    private var usernameSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Username")
                Text(viewModel.username)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                UIPasteboard.general.string = viewModel.username
            }, label: {
                Image(uiImage: IconProvider.squares)
                    .foregroundColor(.secondary)
            })
        }
    }

    private var urlsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Websites")
            VStack(spacing: 4) {
                ForEach(viewModel.urls, id: \.self) { url in
                    Text(url)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var passwordSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Password")

                if isShowingPassword {
                    Text(viewModel.password)
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    let hiddenPassword = viewModel.password.map { _ in "•" }.joined()
                    Text(hiddenPassword)
                        .font(.callout)
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingPassword.toggle()
                    }
                }, label: {
                    Text("Reveal Password")
                        .font(.callout)
                        .foregroundColor(ColorProvider.BrandNorm)
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                UIPasteboard.general.string = viewModel.password
            }, label: {
                Image(uiImage: IconProvider.squares)
                    .foregroundColor(.secondary)
            })
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Note")
            Text(viewModel.note)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
