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
    @Namespace private var contentID
    @State private var isShowingDiscardAlert = false

    init(viewModel: CreateEditNoteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { value in
                ScrollView {
                    LazyVStack {
                        TextEditorWithPlaceholder(text: $viewModel.name,
                                                  isFocused: $isFocusedOnTitle,
                                                  placeholder: "Untitled",
                                                  submitLabel: .next)
                        .font(.title.weight(.bold))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)

                        TextEditorWithPlaceholder(text: $viewModel.note,
                                                  isFocused: $isFocusedOnContent,
                                                  placeholder: "Tap here to continue")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(contentID)

                        Spacer()
                    }
                    .padding()
                }
                .onChange(of: viewModel.name) { name in
                    // When users press enter, move the cursor to content
                    if name.last == "\n" {
                        viewModel.name.removeLast()
                        isFocusedOnContent = true
                    }
                    withAnimation {
                        value.scrollTo(contentID, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.note) { _ in
                    withAnimation {
                        value.scrollTo(contentID, anchor: .bottom)
                    }
                }
            }
            .accentColor(Color(uiColor: viewModel.itemContentType().tintColor)) // Remove when dropping iOS 15
            .tint(Color(uiColor: viewModel.itemContentType().tintColor))
            .background(Color.passBackground)
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
            if #available(iOS 16, *) {
                isFocusedOnTitle = true
            } else {
                // 0.5 second delay is purely heuristic.
                // Values lower than 0.5 simply don't work.
                // Can be removed once iOS 15 is dropped
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocusedOnTitle = true
                }
            }
        }
    }
}
