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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateEditAliasView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditAliasViewModel
    @FocusState private var isFocusedOnTitle: Bool
    @FocusState private var isFocusedOnPrefix: Bool
    @FocusState private var isFocusedOnNote: Bool
    @State private var noteSectionId = UUID().uuidString
    @State private var isShowingDiscardAlert = false

    private var tintColor: UIColor { viewModel.itemContentType().tintColor }

    init(viewModel: CreateEditAliasViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .toolbar { closeButtonToolbar }

                case .error(let error):
                    RetryableErrorView(errorMessage: error.messageForTheUser,
                                       onRetry: viewModel.getAliasAndAliasOptions)
                    .padding()
                    .toolbar { closeButtonToolbar }

                case .loaded:
                    content
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
    }

    private var closeButtonToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         color: tintColor,
                         action: dismiss.callAsFunction)
        }
    }

    private var content: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 8) {
                    CreateEditItemTitleSection(isFocused: _isFocusedOnTitle,
                                               title: $viewModel.title) {
                        if case .create = viewModel.mode {
                            isFocusedOnPrefix.toggle()
                        } else {
                            isFocusedOnNote.toggle()
                        }
                    }

                    if case .edit = viewModel.mode {
                        aliasReadonlySection
                    } else {
                        aliasPreviewSection
                        prefixSuffixSection
                    }
                    mailboxesSection

                    NoteEditSection(
                        isFocused: _isFocusedOnNote,
                        note: $viewModel.note,
                        onBeginEditing: {
                            isFocusedOnTitle = false
                            isFocusedOnPrefix = false
                        })
                    .id(noteSectionId)
                }
                .padding()
            }
            .onChange(of: viewModel.note) { _ in
                value.scrollTo(noteSectionId, anchor: .bottom)
            }
        }
        .tint(Color(uiColor: tintColor))
        .onFirstAppear {
            if case .create = viewModel.mode {
                isFocusedOnTitle.toggle()
            }
        }
        .toolbar {
            CreateEditItemToolbar(
                saveButtonTitle: viewModel.saveButtonTitle(),
                isSaveable: viewModel.isSaveable,
                isSaving: viewModel.isSaving,
                itemContentType: viewModel.itemContentType(),
                onGoBack: {
                    if viewModel.isEmpty {
                        dismiss()
                    } else {
                        isShowingDiscardAlert.toggle()
                    }
                },
                onSave: viewModel.save)
        }
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

    private var aliasPreviewSection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.alias,
                                  color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Alias preview")
                    .sectionTitleText()

                if let prefixError = viewModel.prefixError {
                    Text(prefixError.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    if viewModel.prefix.isEmpty {
                        Text("prefix")
                            .foregroundColor(.textWeak) +
                        Text(viewModel.suffix)
                            .foregroundColor(Color(uiColor: tintColor))
                    } else {
                        Text(viewModel.prefix + viewModel.suffix)
                            .foregroundColor(Color(uiColor: tintColor))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.default, value: viewModel.prefixError)
        .padding(kItemDetailSectionPadding)
        .roundedDetailSection()
    }

    private var prefixSuffixSection: some View {
        VStack(alignment: .leading, spacing: kItemDetailSectionPadding) {
            prefixRow
            Divider()
            suffixRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedEditableSection()
    }

    private var prefixRow: some View {
        VStack(alignment: .leading) {
            Text("Prefix")
                .sectionTitleText()
            TextField("Add a prefix", text: $viewModel.prefix)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .focused($isFocusedOnPrefix)
                .submitLabel(.done)
                .onSubmit { isFocusedOnNote.toggle() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, kItemDetailSectionPadding)
    }

    @ViewBuilder
    private var suffixRow: some View {
        if let suffixes = viewModel.suffixSelection?.suffixes {
            Menu(content: {
                ForEach(suffixes, id: \.suffix) { suffix in
                    Button(action: {
                        viewModel.suffixSelection?.selectedSuffix = suffix
                    }, label: {
                        Label(title: {
                            Text(suffix.suffix)
                        }, icon: {
                            if suffix.suffix == viewModel.suffixSelection?.selectedSuffix?.suffix {
                                Image(systemName: "checkmark")
                            }
                        })
                    })
                }
            }, label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Suffix")
                            .sectionTitleText()
                        Text(viewModel.suffix)
                            .sectionContentText()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    ItemDetailSectionIcon(icon: IconProvider.chevronDown,
                                          color: .textWeak)
                }
                .padding(.horizontal, kItemDetailSectionPadding)
                .transaction { transaction in
                    transaction.animation = nil
                }
            })
        } else {
            EmptyView()
        }
    }

    private var mailboxesSection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.forward, color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Forwarded to")
                    .sectionTitleText()
                Text(viewModel.mailboxes)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ItemDetailSectionIcon(icon: IconProvider.chevronDown, color: .textWeak)
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
        .contentShape(Rectangle())
        .onTapGesture(perform: viewModel.showMailboxSelection)
    }
}

struct MailboxesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var mailboxSelection: MailboxSelection
    let mode: Mode

    enum Mode {
        case createEditAlias
        case createAliasLite

        var tintColor: Color {
            switch self {
            case .createEditAlias:
                return Color(uiColor: ItemContentType.alias.tintColor)
            case .createAliasLite:
                return Color(uiColor: ItemContentType.login.tintColor)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(mailboxSelection.mailboxes, id: \.ID) { mailbox in
                    HStack {
                        Text(mailbox.email)
                            .foregroundColor(isSelected(mailbox) ? mode.tintColor : .textNorm)
                        Spacer()

                        if isSelected(mailbox) {
                            Image(uiImage: IconProvider.checkmark)
                                .foregroundColor(mode.tintColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        mailboxSelection.selectedMailboxes.insertOrRemove(mailbox, minItemCount: 1)
                    }
                }
            }
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        NotchView()
                        Text("Forward to")
                            .navigationTitleText()
                    }
                }
            }
        }
    }

    private func isSelected(_ mailbox: Mailbox) -> Bool {
        mailboxSelection.selectedMailboxes.contains(mailbox)
    }
}
