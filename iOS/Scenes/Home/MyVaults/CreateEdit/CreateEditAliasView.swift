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

import Client
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
                    content
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.navigationBarTitle())
            .toolbar { toolbarContent }
        }
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
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

        ToolbarItem(placement: .navigationBarTrailing) {
            SpinnerButton(title: "Save",
                          disabled: !viewModel.state.isLoaded || !viewModel.isSaveable,
                          spinning: viewModel.isSaving,
                          action: viewModel.save)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 8) {
                titleSection
                if case .edit = viewModel.mode {
                    aliasReadonlySection
                } else {
                    aliasInputView
                }
                mailboxesSection
                noteInputView
            }
            .padding()
        }
        .tint(Color(uiColor: viewModel.itemContentType().tintColor))
    }

    private var titleSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Title")
                    .sectionTitleText()
                TextField("Untitled", text: $viewModel.title)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                viewModel.title = ""
            }, label: {
                ItemDetailSectionIcon(icon: IconProvider.cross,
                                      color: .textWeak)
            })
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
    }

    private var aliasReadonlySection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.alias,
                                  color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Alias address")
                    .sectionTitleText()
                Text(viewModel.aliasEmail)
                    .foregroundColor(.textWeak)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(kItemDetailSectionPadding)
        .roundedDetailSection()
    }

    private var aliasInputView: some View {
        VStack {
            UserInputContainerView(title: "Alias",
                                   isFocused: isFocusedOnPrefix) {
                UserInputContentSingleLineWithClearButton(
                    text: $viewModel.prefix,
                    isFocused: $isFocusedOnPrefix,
                    placeholder: "Custom prefix",
                    onClear: { viewModel.prefix = "" },
                    textAutocapitalizationType: .none,
                    autocorrectionDisabled: true)
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

    private var mailboxesSection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.forward,
                                  color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Forwarded to")
                    .sectionTitleText()
                Text(viewModel.mailboxes)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ItemDetailSectionIcon(icon: IconProvider.chevronDown,
                                  color: .textWeak)
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.showMailboxSelection()
        }
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
    let tintColor = Color(uiColor: ItemContentType.alias.tintColor)

    var body: some View {
        NavigationView {
            List {
                ForEach(mailboxSelection.mailboxes, id: \.ID) { mailbox in
                    HStack {
                        Text(mailbox.email)
                            .foregroundColor(isSelected(mailbox) ? tintColor : .textNorm)
                        Spacer()

                        if isSelected(mailbox) {
                            Image(uiImage: IconProvider.checkmark)
                                .foregroundColor(tintColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        mailboxSelection.selectOrDeselect(mailbox: mailbox)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Forwarded to")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func isSelected(_ mailbox: Mailbox) -> Bool {
        mailboxSelection.selectedMailboxes.contains(mailbox)
    }
}
