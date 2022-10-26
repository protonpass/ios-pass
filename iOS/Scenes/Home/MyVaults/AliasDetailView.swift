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
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AliasDetailViewModel
    @State private var isShowingTrashingAlert = false

    init(viewModel: AliasDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            switch viewModel.aliasState {
            case .loading:
                ProgressView()
            case .loaded(let alias):
                ConcreteAliasDetailView(alias: alias, note: viewModel.itemContent.note)
            case .error(let error):
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: viewModel.getAlias)
                .padding()
            }
        }
        .moveToTrashAlert(isPresented: $isShowingTrashingAlert, onTrash: viewModel.trash)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .onReceive(viewModel.$isTrashed) { isTrashed in
            if isTrashed {
                dismiss()
            }
        }
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
            trailingMenu
                .opacity(viewModel.aliasState.isLoaded ? 1 : 0)
                .disabled(!viewModel.aliasState.isLoaded)
        }
    }

    private var trailingMenu: some View {
        Menu(content: {
            Button(action: viewModel.edit) {
                Label(title: {
                    Text("Edit alias")
                }, icon: {
                    Image(uiImage: IconProvider.eraser)
                })
            }

            Divider()

            DestructiveButton(title: "Move to trash",
                              icon: IconProvider.trash,
                              action: {
                isShowingTrashingAlert.toggle()
            })
        }, label: {
            Image(uiImage: IconProvider.threeDotsHorizontal)
                .foregroundColor(.primary)
        })
    }
}

private struct ConcreteAliasDetailView: View {
    let alias: Alias
    let note: String

    var body: some View {
        VStack(spacing: 32) {
            aliasSection
            mailboxesSection
            noteSection
            Spacer()
        }
        .padding()
        .padding(.top)
    }

    private var aliasSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Alias")

            HStack {
                Text(alias.email)
                    .font(.callout)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    UIPasteboard.general.string = alias.email
                }, label: {
                    Image(uiImage: IconProvider.squares)
                        .foregroundColor(.secondary)
                })
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mailboxesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mailboxes")
            Text(alias.mailboxes.map { $0.email }.joined(separator: "\n"))
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
            if note.isEmpty {
                Text("Empty note")
                    .modifier(ItalicSecondaryTextStyle())
            } else {
                Text(note)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
