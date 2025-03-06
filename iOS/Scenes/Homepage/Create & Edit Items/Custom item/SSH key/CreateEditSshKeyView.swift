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
import Screens
import SwiftUI

private enum SshKeyType: Int, Sendable, Identifiable {
    case `public`, `private`

    var id: Int {
        rawValue
    }

    var title: LocalizedStringKey {
        switch self {
        case .public: "Public key"
        case .private: "Private key"
        }
    }

    var placeholder: LocalizedStringKey {
        switch self {
        case .public: "Add public key"
        case .private: "Add private key"
        }
    }
}

struct CreateEditSshKeyView: View {
    @StateObject private var viewModel: CreateEditSshKeyViewModel
    @FocusState private var focusedField: Field?
    @State private var selectedKeyType: SshKeyType?

    enum Field: CustomFieldTypes {
        case title
        case custom(CustomFieldUiModel?)
    }

    init(viewModel: CreateEditSshKeyViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                title
                view(for: .private, value: viewModel.privateKey)
                view(for: .public, value: viewModel.publicKey)
                fields
                AddCustomFieldAndSectionView(onAddField: { viewModel.addCustomField(to: nil) },
                                             onAddSection: viewModel.customSectionUiModels.isEmpty ?
                                                 { addCustomSection() } : nil)
                if viewModel.fileAttachmentsEnabled {
                    FileAttachmentsEditSection(files: viewModel.fileUiModels,
                                               isFetching: viewModel.isFetchingAttachedFiles,
                                               fetchError: viewModel.fetchAttachedFilesError,
                                               isUploading: viewModel.isUploadingFile,
                                               handler: viewModel)
                }
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
        .sheet(item: $selectedKeyType) { keyType in
            SshKeyEditor(title: keyType.title,
                         value: keyType == .public ? viewModel.publicKey : viewModel.privateKey,
                         onSave: { newValue in
                             switch keyType {
                             case .public:
                                 viewModel.publicKey = newValue
                             case .private:
                                 viewModel.privateKey = newValue
                             }
                         })
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

    func view(for keyType: SshKeyType, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text(keyType.title)
                .editableSectionTitleText(for: value)

            TextField(keyType.placeholder,
                      text: keyType == .public ?
                          .constant(value) :
                          .constant(String(repeating: "•", count: value.count)))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(PassColor.textNorm.toColor)
                .disabled(true)
                .if(!value.isEmpty) { view in
                    view.monospaced()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
        .buttonEmbeded {
            focusedField = nil
            selectedKeyType = keyType
        }
    }

    var fields: some View {
        ForEach(viewModel.customFieldUiModels, id: \.self) { field in
            EditCustomFieldView(focusedField: $focusedField,
                                field: .custom(field),
                                contentType: viewModel.itemContentType,
                                uiModel: .constant(field),
                                showIcon: false,
                                onEditTitle: { viewModel.editCustomFieldTitle(field) },
                                onRemove: {
                                    // Work around a crash in later versions of iOS 17
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        viewModel.customFieldUiModels.removeAll(where: { $0.id == field.id })
                                    }
                                })
        }
    }

    func addCustomSection() {
        viewModel.showAddCustomSectionAlert.toggle()
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
            .keyboardType(.asciiCapable)
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
