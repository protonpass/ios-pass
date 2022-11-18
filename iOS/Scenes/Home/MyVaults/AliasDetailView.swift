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

    init(viewModel: AliasDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            switch viewModel.aliasState {
            case .loading:
                ProgressView()
            case .loaded(let alias):
                ConcreteAliasDetailView(viewModel: viewModel,
                                        alias: alias,
                                        note: viewModel.itemContent.note)
            case .error(let error):
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: viewModel.getAlias)
                .padding()
            }
        }
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
}

private struct ConcreteAliasDetailView: View {
    @ObservedObject var viewModel: AliasDetailViewModel
    let alias: Alias
    let note: String

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                aliasSection
                mailboxesSection
                    .padding(.vertical)
                noteSection
                Spacer()
            }
            .padding()
        }
    }

    private var aliasSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alias")
                .sectionTitleText()

            Text(alias.email)
                .sectionContentText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.copyAliasEmail(alias.email)
                }
                .contextMenu {
                    Button(action: {
                        viewModel.copyAliasEmail(alias.email)
                    }, label: {
                        Text("Copy")
                    })

                    Button(action: {
                        viewModel.showLarge(alias.email)
                    }, label: {
                        Text("Show large")
                    })
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .roundedDetail()
    }

    private var mailboxesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mailboxes")
                .sectionTitleText()

            ForEach(alias.mailboxes, id: \.ID) { mailbox in
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

                if mailbox != alias.mailboxes.last {
                    Divider()
                        .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .contentShape(Rectangle())
        .roundedDetail()
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note")
                .sectionTitleText()

            if note.isEmpty {
                Text("Empty note")
                    .placeholderText()
            } else {
                Text(note)
                    .sectionContentText()
                    .contextMenu {
                        Button(action: {
                            viewModel.copyNote(note)
                        }, label: {
                            Text("Copy")
                        })
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}
