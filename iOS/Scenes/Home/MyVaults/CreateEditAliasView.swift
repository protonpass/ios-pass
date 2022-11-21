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
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditAliasViewModel
    @State private var isFocusedOnTitle = false
    @State private var isFocusedOnPrefix = false
    @State private var isFocusedOnNote = false
    @State private var isShowingTrashAlert = false
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

                            if viewModel.mode.isEditMode {
                                MoveToTrashButton {
                                    isShowingTrashAlert.toggle()
                                }
                                .opacityReduced(viewModel.isSaving)
                            }
                        }
                        .padding()
                    }
                }
            }
            .toolbar { toolbarContent }
            .navigationBarTitleDisplayMode(.inline)
        }
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
        .moveToTrashAlert(isPresented: $isShowingTrashAlert, onTrash: viewModel.trash)
        .onReceiveBoolean(viewModel.$isTrashed, perform: dismiss.callAsFunction)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                if viewModel.isEmpty {
                    dismiss()
                } else {
                    isShowingDiscardAlert.toggle()
                }
            }, label: {
                Text("Cancel")
            })
            .foregroundColor(Color(.label))
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.navigationBarTitle())
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            SpinnerButton(title: "Save",
                          disabled: !viewModel.state.isLoaded || !viewModel.isSaveable,
                          spinning: viewModel.isSaving,
                          action: viewModel.save)
        }
    }

    private var titleInputView: some View {
        UserInputContainerView(title: "Title",
                               isFocused: isFocusedOnTitle) {
            UserInputContentSingleLineView(
                text: $viewModel.title,
                isFocused: $isFocusedOnTitle,
                placeholder: "Alias name")
            .opacityReduced(viewModel.isSaving)
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
                        .opacityReduced(!isFocusedOnPrefix, reducedOpacity: 0)
                        .animation(.linear(duration: 0.1), value: isFocusedOnPrefix)
                    },
                    trailingAction: { viewModel.prefix = "" },
                    textAutocapitalizationType: .none)
                .opacityReduced(viewModel.isSaving)
            }

            UserInputContainerView(title: nil, isFocused: false) {
                if let suffixes = viewModel.suffixSelection?.suffixes {
                    Menu(content: {
                        ForEach(suffixes, id: \.suffix) { suffix in
                            Button(action: {
                                viewModel.suffixSelection?.selectedSuffix = suffix
                            }, label: {
                                Label(title: {
                                    Text(suffix.suffix)
                                }, icon: {
                                    if suffix.suffix == viewModel.suffix {
                                        Image(systemName: "checkmark")
                                    }
                                })
                            })
                        }
                    }, label: {
                        UserInputStaticContentView(text: viewModel.suffix) {
                            Image(uiImage: IconProvider.chevronDown)
                                .foregroundColor(.textNorm)
                        }
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                    })
                } else {
                    EmptyView()
                }
            }
            .buttonStyle(.plain)
            .opacityReduced(viewModel.isSaving)

            if !viewModel.prefix.isEmpty {
                if let prefixError = viewModel.prefixError {
                    Text(prefixError.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.default, value: viewModel.prefixError)
                } else {
                    fullAlias
                        .animation(.default, value: viewModel.prefixError)
                }
            }
        }
    }

    private var fullAlias: some View {
        HStack {
            Group {
                Text("You're about to create alias ")
                    .foregroundColor(.secondary) +
                Text(viewModel.prefix + viewModel.suffix)
                    .foregroundColor(.interactionNorm)
            }
            .font(.caption)
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(AnyTransition.opacity.animation(.linear(duration: 0.2)))
    }

    private var mailboxesInputView: some View {
        UserInputContainerView(title: "Mailboxes", isFocused: false) {
            UserInputStaticContentView(text: viewModel.mailboxes) {
                Image(uiImage: IconProvider.chevronDown)
                    .foregroundColor(.textNorm)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.showMailboxSelection()
            }
        }
        .opacityReduced(viewModel.isSaving)
    }

    private var noteInputView: some View {
        UserInputContainerView(title: "Note",
                               isFocused: isFocusedOnNote) {
            UserInputContentMultilineView(
                text: $viewModel.note,
                isFocused: $isFocusedOnNote)
            .opacityReduced(viewModel.isSaving)
        }
    }
}

struct MailboxesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var mailboxSelection: MailboxSelection

    var body: some View {
        VStack {
            NotchView()
                .padding(.top, 5)
                .padding(.bottom, 7)

            Text("Destination mailboxes")
                .fontWeight(.bold)

            List {
                ForEach(mailboxSelection.mailboxes, id: \.ID) { mailbox in
                    HStack {
                        Text(mailbox.email)
                            .foregroundColor(.textNorm)
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
        }
    }
}
