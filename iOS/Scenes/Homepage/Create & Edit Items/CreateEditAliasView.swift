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
    @Namespace private var noteID
    @State private var isShowingAdvancedOptions = false
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .background(Color(uiColor: PassColor.backgroundNorm))
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
    }

    private var closeButtonToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: ItemContentType.alias.tintColor,
                         backgroundColor: ItemContentType.alias.backgroundWeakColor,
                         action: dismiss.callAsFunction)
        }
    }

    private var content: some View {
        ScrollViewReader { value in
            ScrollView {
                LazyVStack(spacing: 8) {
                    CreateEditItemTitleSection(isFocused: $isFocusedOnTitle,
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
                        if isShowingAdvancedOptions, let suffixSelection = viewModel.suffixSelection {
                            PrefixSuffixSection(prefix: $viewModel.prefix,
                                                prefixManuallyEdited: $viewModel.prefixManuallyEdited,
                                                suffixSelection: suffixSelection,
                                                prefixError: viewModel.prefixError)
                        } else {
                            AdvancedOptionsSection(isShowingAdvancedOptions: $isShowingAdvancedOptions)
                                .padding(.vertical)
                        }
                    }

                    if let mailboxSelection = viewModel.mailboxSelection {
                        MailboxSection(mailboxSelection: mailboxSelection)
                            .onTapGesture(perform: viewModel.showMailboxSelection)
                    }

                    NoteEditSection(note: $viewModel.note, isFocused: $isFocusedOnNote)
                        .id(noteID)
                }
                .padding()
                .animation(.default, value: isShowingAdvancedOptions)
            }
            .onChange(of: isFocusedOnNote) { isFocusedOnNote in
                if isFocusedOnNote {
                    withAnimation {
                        value.scrollTo(noteID, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.note) { _ in
                withAnimation {
                    value.scrollTo(noteID, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isSaving) { isSaving in
                if isSaving {
                    isFocusedOnTitle = false
                    isFocusedOnPrefix = false
                    isFocusedOnNote = false
                }
            }
        }
        .accentColor(Color(uiColor: viewModel.itemContentType().tintColor)) // Remove when dropping iOS 15
        .tint(Color(uiColor: tintColor))
        .onFirstAppear {
            if case .create = viewModel.mode {
                if #available(iOS 16, *) {
                    isFocusedOnTitle.toggle()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        isFocusedOnTitle.toggle()
                    }
                }
            }
        }
        .toolbar {
            CreateEditItemToolbar(
                saveButtonTitle: viewModel.saveButtonTitle(),
                isSaveable: viewModel.isSaveable,
                isSaving: viewModel.isSaving,
                itemContentType: viewModel.itemContentType(),
                onGoBack: {
                    if viewModel.didEditSomething {
                        isShowingDiscardAlert.toggle()
                    } else {
                        dismiss()
                    }
                },
                onSave: viewModel.save)
        }
    }

    private var aliasReadonlySection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.alias, color: tintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Alias address")
                    .sectionTitleText()
                Text(viewModel.aliasEmail)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(kItemDetailSectionPadding)
        .roundedDetailSection()
    }

    private var aliasPreviewSection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.alias)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Alias preview")
                    .sectionTitleText()

                if viewModel.prefixError != nil {
                    Text(viewModel.prefix + viewModel.suffix)
                        .foregroundColor(Color(uiColor: PassColor.signalDanger))
                } else {
                    Text(viewModel.prefix)
                        .foregroundColor(Color(uiColor: PassColor.textNorm)) +
                    Text(viewModel.suffix)
                        .foregroundColor(Color(uiColor: tintColor))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.default, value: viewModel.prefixError)
        .padding(kItemDetailSectionPadding)
        .roundedDetailSection()
    }
}
