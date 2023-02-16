//
// CreateEditNoteView.swift
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateEditNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditNoteViewModel
    @FocusState private var isFocusedOnTitle: Bool
    @FocusState private var isFocusedOnContent: Bool
    @State private var isShowingDiscardAlert = false

    init(viewModel: CreateEditNoteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    TextEditorWithPlaceholder(text: $viewModel.name,
                                              isFocused: _isFocusedOnTitle,
                                              placeholder: "Untitled")
                    .font(.title.weight(.bold))
                    .focused($isFocusedOnTitle)
                    .submitLabel(.next)
                    .onChange(of: viewModel.name) { name in
                        // When users press enter, move the cursor to content
                        if name.last == "\n" {
                            viewModel.name.removeLast()
                            isFocusedOnContent = true
                        }
                    }

                    TextEditorWithPlaceholder(text: $viewModel.note,
                                              isFocused: _isFocusedOnContent,
                                              placeholder: "Tap here to continue")
                }
                .padding()
            }
            .accentColor(Color(uiColor: viewModel.itemContentType().tintColor))
            .navigationBarTitleDisplayMode(.inline)
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
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
        .onFirstAppear {
            isFocusedOnTitle = true
        }
    }
}
