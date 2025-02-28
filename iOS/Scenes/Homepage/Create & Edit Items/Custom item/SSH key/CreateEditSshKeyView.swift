//
// CreateEditSshKeyView.swift
// Proton Pass - Created on 27/02/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CreateEditSshKeyView: View {
    @StateObject private var viewModel: CreateEditSshKeyViewModel
    @FocusState private var focusedField: Field?
    @State private var showPrivateKeyEditor = false
    @State private var showPublicKeyEditor = false

    enum Field {
        case title
    }

    init(viewModel: CreateEditSshKeyViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                title
                privateKey
                publicKey
            }
            .padding()
        }
        .fullSheetBackground()
        .itemCreateEditSetUp(viewModel)
        .navigationStackEmbeded()
        .onFirstAppear {
            if case .create = viewModel.mode {
                focusedField = .title
            }
        }
        .sheet(isPresented: $showPrivateKeyEditor) {
            SshKeyEditor(title: "Private key",
                         value: viewModel.privateKey,
                         onSave: { viewModel.privateKey = $0 })
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showPublicKeyEditor) {
            SshKeyEditor(title: "Public key",
                         value: viewModel.publicKey,
                         onSave: { viewModel.publicKey = $0 })
                .interactiveDismissDisabled()
        }
    }
}

private extension CreateEditSshKeyView {
    var title: some View {
        CreateEditItemTitleSection(title: $viewModel.title,
                                   focusedField: $focusedField,
                                   field: .title,
                                   itemContentType: viewModel.itemContentType,
                                   isEditMode: viewModel.mode.isEditMode,
                                   onSubmit: nil)
            .padding(.bottom, DesignConstant.sectionPadding / 2)
    }

    var privateKey: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Private key")
                .editableSectionTitleText(for: viewModel.privateKey)

            TextField("Add private key",
                      text: .constant(String(repeating: "•", count: viewModel.privateKey.count)))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(PassColor.textNorm.toColor)
                .disabled(true)
                .if(!viewModel.privateKey.isEmpty) { view in
                    view.monospaced()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
        .buttonEmbeded {
            focusedField = nil
            showPrivateKeyEditor.toggle()
        }
    }

    var publicKey: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Public key")
                .editableSectionTitleText(for: viewModel.publicKey)

            TextField("Add public key", text: .constant(viewModel.publicKey))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(PassColor.textNorm.toColor)
                .disabled(true)
                .if(!viewModel.publicKey.isEmpty) { view in
                    view.monospaced()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
        .buttonEmbeded {
            focusedField = nil
            showPublicKeyEditor.toggle()
        }
    }
}

private struct SshKeyEditor: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused
    @State private var showDiscardAlert = false
    @State private var value = ""
    private let title: LocalizedStringKey
    private let onSave: (String) -> Void

    init(title: LocalizedStringKey,
         value: String,
         onSave: @escaping (String) -> Void) {
        self.title = title
        _value = .init(initialValue: value)
        self.onSave = onSave
    }

    var body: some View {
        TextEditor(text: $value)
            .focused($isFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .monospaced()
            .foregroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollContentBackground(.hidden)
            .padding([.horizontal, .bottom])
            .fullSheetBackground()
            .discardChangesAlert(isPresented: $showDiscardAlert,
                                 onDiscard: dismiss.callAsFunction)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Close",
                                 action: { showDiscardAlert.toggle() })
                }

                ToolbarItem(placement: .principal) {
                    Text(title)
                        .navigationTitleText()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    CapsuleTextButton(title: #localized("Save"),
                                      titleColor: PassColor.textInvert,
                                      backgroundColor: PassColor.interactionNormMajor1,
                                      height: 44,
                                      action: { dismiss(); onSave(value) })
                        .accessibilityLabel("Save")
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        if let string = UIPasteboard.general.string {
                            value = string
                        }
                    }, label: {
                        // Use HStack instead of Label because Label's text is not rendered in toolbar
                        HStack {
                            Image(systemName: "list.clipboard")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18)
                            Text("Paste from clipboard")
                        }
                    })
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .tint(PassColor.interactionNormMajor2.toColor)
            .navigationStackEmbeded()
            .onAppear {
                isFocused = true
            }
    }
}
