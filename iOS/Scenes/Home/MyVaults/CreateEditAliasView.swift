//
// CreateEditAliasView.swift
// Proton Pass - Created on 07/07/2022.
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

import Combine
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateEditAliasView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CreateEditAliasViewModel
    @State private var isFocusedOnTitle = false
    @State private var isFocusedOnPrefix = false
    @State private var isFocusedOnNote = false
    @State private var isShowingDiscardAlert = false

    init(viewModel: CreateEditAliasViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.state {
                case .loading:
                    ProgressView()

                case .error(let error):
                    RetryableErrorView(errorMessage: error.messageForTheUser,
                                       onRetry: viewModel.getAliasAndAliasOptions)
                    .padding()

                case .loaded:
                    ScrollView {
                        VStack(spacing: 20) {
                            titleInputView
                            if case .edit = viewModel.mode {
                                aliasEmailView
                            } else {
                                aliasInputView
                            }
                            mailboxesInputView
                            noteInputView
                        }
                        .padding()
                    }
                    .discardChangesAlert(isPresented: $isShowingDiscardAlert) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .toolbar { toolbarContent }
            .navigationBarTitleDisplayMode(.inline)
        }
        .disabled(viewModel.isLoading)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                isShowingDiscardAlert.toggle()
            }, label: {
                Image(uiImage: IconProvider.cross)
            })
            .foregroundColor(Color(.label))
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.navigationBarTitle())
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.save) {
                Text("Save")
                    .fontWeight(.bold)
                    .foregroundColor(.brandNorm)
            }
            .opacity(viewModel.state.isLoaded ? 1 : 0)
            .disabled(!viewModel.state.isLoaded)
        }
    }

    private var titleInputView: some View {
        UserInputContainerView(title: "Title",
                               isFocused: isFocusedOnTitle) {
            UserInputContentSingleLineView(
                text: $viewModel.title,
                isFocused: $isFocusedOnTitle,
                placeholder: "Alias name")
        }
    }

    private var aliasEmailView: some View {
        UserInputContainerView(title: "Alias",
                               isFocused: false,
                               isEditable: false) {
            Text(viewModel.aliasEmail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var aliasInputView: some View {
        VStack {
            UserInputContainerView(title: "Alias",
                                   isFocused: isFocusedOnPrefix) {
                UserInputContentSingleLineWithTrailingView(
                    text: $viewModel.prefix,
                    isFocused: $isFocusedOnPrefix,
                    placeholder: "Prefix",
                    trailingView: {
                        Image(uiImage: IconProvider.crossCircleFilled)
                        .foregroundColor(.secondary)
                        .opacity(isFocusedOnPrefix ? 1 : 0)
                        .disabled(!isFocusedOnPrefix)
                    },
                    trailingAction: { viewModel.prefix = "" },
                    textAutocapitalizationType: .none)
            }

            NavigationLink(destination: {
                SuffixesView(suffixSelection: viewModel.suffixSelection ?? .init(suffixes: []))
            }, label: {
                UserInputContainerView(title: nil, isFocused: false) {
                    UserInputStaticContentView(text: $viewModel.suffix)
                }
            })
            .buttonStyle(.plain)

            if !viewModel.prefix.isEmpty {
                HStack {
                    Group {
                        Text("You're about to create alias ")
                            .foregroundColor(.secondary) +
                        Text(viewModel.prefix + viewModel.suffix)
                            .foregroundColor(.brandNorm)
                    }
                    .font(.caption)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(AnyTransition.opacity.animation(.linear(duration: 0.2)))
            }
        }
    }

    private var mailboxesInputView: some View {
        NavigationLink(destination: {
            MailboxesView(mailboxSelection: viewModel.mailboxSelection ?? .init(mailboxes: []))
        }, label: {
            UserInputContainerView(title: "Mailboxes", isFocused: false) {
                UserInputStaticContentView(text: $viewModel.mailboxes)
            }
        })
        .buttonStyle(.plain)
    }

    private var noteInputView: some View {
        UserInputContainerView(title: "Note",
                               isFocused: isFocusedOnNote) {
            UserInputContentMultilineView(
                text: $viewModel.note,
                isFocused: $isFocusedOnNote)
        }
    }
}

private struct SuffixesView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var suffixSelection: SuffixSelection

    var body: some View {
        List {
            ForEach(suffixSelection.suffixes, id: \.suffix) { suffix in
                HStack {
                    Text(suffix.suffix)
                    Spacer()
                    if suffixSelection.selectedSuffix == suffix {
                        Image(uiImage: IconProvider.checkmark)
                            .foregroundColor(.brandNorm)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    suffixSelection.selectedSuffix = suffix
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .listStyle(.plain)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(uiImage: IconProvider.chevronLeft)
                    .foregroundColor(.primary)
            })
        }

        ToolbarItem(placement: .principal) {
            Text("Alias suffixes")
                .fontWeight(.bold)
        }
    }
}

private struct MailboxesView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var mailboxSelection: MailboxSelection

    var body: some View {
        List {
            ForEach(mailboxSelection.mailboxes, id: \.ID) { mailbox in
                HStack {
                    Text(mailbox.email)
                    Spacer()
                    if mailboxSelection.selectedMailboxes.contains(mailbox) {
                        Image(uiImage: IconProvider.checkmark)
                            .foregroundColor(.brandNorm)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    mailboxSelection.selectOrDeselect(mailbox: mailbox)
                }
            }
        }
        .listStyle(.plain)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(uiImage: IconProvider.chevronLeft)
                    .foregroundColor(.primary)
            })
        }

        ToolbarItem(placement: .principal) {
            Text("Alias suffixes")
                .fontWeight(.bold)
        }
    }
}
