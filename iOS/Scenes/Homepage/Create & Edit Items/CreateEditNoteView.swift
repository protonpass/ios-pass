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

import DesignSystem
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CreateEditNoteView: View {
    private let theme = resolve(\SharedToolingContainer.theme)
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditNoteViewModel
    @FocusState private var focusedField: Field?
    @State private var isShowingDiscardAlert = false
    private let dummyId = UUID().uuidString

    init(viewModel: CreateEditNoteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    enum Field {
        case title, content
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        CreateEditItemTitleSection(title: .constant(""),
                                                   focusedField: $focusedField,
                                                   field: .title,
                                                   selectedVault: viewModel.selectedVault,
                                                   itemContentType: viewModel.itemContentType(),
                                                   isEditMode: viewModel.mode.isEditMode,
                                                   onChangeVault: { viewModel.changeVault() })
                            .padding(.bottom, 18)

                        TextEditorWithPlaceholder(text: $viewModel.title,
                                                  focusedField: $focusedField,
                                                  field: .title,
                                                  placeholder: #localized("Untitled"),
                                                  font: .title,
                                                  fontWeight: .bold,
                                                  onSubmit: { focusedField = .content })

                        Text(verbatim: "")
                            .id(dummyId)

                        TextEditorWithPlaceholder(text: $viewModel.note,
                                                  focusedField: $focusedField,
                                                  field: .content,
                                                  placeholder: #localized("Note"))
                    }
                    .padding()
                }
                .onAppear {
                    // Workaround a SwiftUI bug that causes the text editors to be scrolled
                    // to bottom when it's first focused
                    // https://stackoverflow.com/q/75403453/2034535
                    proxy.scrollTo(dummyId)
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
                CreateEditItemToolbar(saveButtonTitle: viewModel.saveButtonTitle(),
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
                                      onScan: { viewModel.openScanner() },
                                      onSave: { viewModel.save() })
            }
        }
        .navigationViewStyle(.stack)
        .theme(theme)
        .tint(viewModel.itemContentType().normMajor1Color.toColor)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
        .scannerSheet(isPresented: $viewModel.isShowingScanner,
                      interpreter: viewModel.interpretor,
                      resultStream: viewModel.scanResponsePublisher)
        .onFirstAppear {
            focusedField = .title
        }
    }
}
