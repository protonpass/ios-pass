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
    @Environment(\.dismiss) private var dismiss
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
        .padding(.top)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: dismiss.callAsFunction) {
                Image(uiImage: IconProvider.chevronLeft)
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.name)
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.edit) {
                Text("Edit")
                    .foregroundColor(.interactionNorm)
            }
        }
    }

    private var usernameSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Username")

                if viewModel.username.isEmpty {
                    Text("No username")
                        .modifier(ItalicSecondaryTextStyle())
                } else {
                    Text(viewModel.username)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.username.isEmpty {
                Button(action: {
                    UIPasteboard.general.string = viewModel.username
                }, label: {
                    Image(uiImage: IconProvider.squares)
                        .foregroundColor(.secondary)
                })
            }
        }
    }

    private var urlsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Websites")
            VStack(alignment: .leading, spacing: 4) {
                ForEach(viewModel.urls, id: \.self) { url in
                    Text(url)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.default, value: viewModel.urls)
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
                        .foregroundColor(.brandNorm)
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
            if viewModel.note.isEmpty {
                Text("Empty note")
                    .modifier(ItalicSecondaryTextStyle())
            } else {
                Text(viewModel.note)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
