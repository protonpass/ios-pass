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
    @FocusState private var focusedField: Field?
    @Namespace private var contentID
    @State private var isShowingDiscardAlert = false

    init(viewModel: CreateEditNoteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    enum Field {
        case title, content
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { value in
                ScrollView {
                    LazyVStack {
                        CreateEditItemTitleSection(title: .constant(""),
                                                   focusedField: $focusedField,
                                                   field: .title,
                                                   selectedVault: viewModel.vault,
                                                   itemContentType: viewModel.itemContentType(),
                                                   isEditMode: viewModel.mode.isEditMode,
                                                   onChangeVault: viewModel.changeVault)
                        .padding(.bottom, 18)

                        TextEditorWithPlaceholder(text: $viewModel.title,
                                                  focusedField: $focusedField,
                                                  field: .title,
                                                  placeholder: "Untitled",
                                                  font: .title,
                                                  fontWeight: .bold,
                                                  onSubmit: { focusedField = .content })

                        TextEditorWithPlaceholder(text: $viewModel.note,
                                                  focusedField: $focusedField,
                                                  field: .content,
                                                  placeholder: "Note")
                        .id(contentID)
                    }
                    .padding()
                }
                .onChange(of: viewModel.note) { _ in
                    withAnimation {
                        value.scrollTo(contentID, anchor: .bottom)
                    }
                }
            }
            .background(Color(uiColor: PassColor.backgroundNorm))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.isSaving) { isSaving in
                if isSaving {
                    focusedField = nil
                }
            }
            .toolbar {
                CreateEditItemToolbar(
                    saveButtonTitle: viewModel.saveButtonTitle(),
                    isSaveable: viewModel.isSaveable,
                    isSaving: viewModel.isSaving,
                    itemContentType: viewModel.itemContentType(),
                    shouldUpgrade: false,
                    onGoBack: {
                        if viewModel.didEditSomething {
                            isShowingDiscardAlert.toggle()
                        } else {
                            dismiss()
                        }
                    },
                    onUpgrade: { /* Not applicable */ },
                    onSave: viewModel.save)
            }
        }
        .navigationViewStyle(.stack)
        // Remove when dropping iOS 15
        .accentColor(Color(uiColor: viewModel.itemContentType().normMajor1Color))
        .tint(Color(uiColor: viewModel.itemContentType().normMajor1Color))
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
        .onFirstAppear {
            if #available(iOS 16, *) {
                focusedField = .title
            } else {
                // 0.5 second delay is purely heuristic.
                // Values lower than 0.5 simply don't work.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .title
                }
            }
        }
    }
}
