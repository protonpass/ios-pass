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
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreateEditSshKeyView: View {
    @StateObject private var viewModel: CreateEditSshKeyViewModel
    @FocusState private var focusedField: Field?
    @State private var lastFocusedField: Field?
    @State private var selectedKeyType: SshKeyType?

    enum Field: CustomFieldTypes {
        case title
        case custom(CustomField?)

        var customField: CustomField? {
            if case let .custom(customField) = self {
                customField
            } else {
                nil
            }
        }
    }

    init(viewModel: CreateEditSshKeyViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                UpsellOrAttachmentsBanner(showUpgrade: viewModel.shouldUpgrade,
                                          showAttachments: viewModel.showFileAttachmentsBanner,
                                          onDismissAttachments: viewModel.dismissFileAttachmentsBanner)

                title
                keys
                fields

                AddCustomFieldAndSectionView(supportAddField: true,
                                             onAddField: { viewModel.requestAddCustomField(to: nil) },
                                             supportAddSection: viewModel.customSections.isEmpty,
                                             onAddSection: addCustomSection)

                sections

                if !viewModel.customSections.isEmpty {
                    PassSectionDivider()
                    AddCustomFieldAndSectionView(supportAddSection: true,
                                                 onAddSection: addCustomSection)
                }

                if viewModel.fileAttachmentsEnabled {
                    FileAttachmentsEditSection(files: viewModel.fileUiModels,
                                               isFetching: viewModel.isFetchingAttachedFiles,
                                               fetchError: viewModel.fetchAttachedFilesError,
                                               isUploading: viewModel.isUploadingFile,
                                               handler: viewModel)
                }
            }
            .padding()
            .toolbar {
                CreateEditKeyboardToolbar(lastFocusedField: $lastFocusedField,
                                          focusedField: focusedField,
                                          onOpenCodeScanner: viewModel.openCodeScanner,
                                          onPasteTotpUri: { viewModel.handlePastingTotpUri(customField: $0) })
            }
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

    var keys: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            view(for: .public, value: viewModel.publicKey)
            PassSectionDivider()
            view(for: .private, value: viewModel.privateKey)
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedEditableSection()
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
        .padding(.horizontal, DesignConstant.sectionPadding)
        .buttonEmbeded {
            focusedField = nil
            selectedKeyType = keyType
        }
    }

    var fields: some View {
        ForEach($viewModel.customFields) { $field in
            EditCustomFieldView(focusedField: $focusedField,
                                field: .custom(field),
                                contentType: viewModel.itemContentType,
                                value: $field,
                                showIcon: false,
                                onEditTitle: { viewModel.requestEditCustomFieldTitle(field) },
                                onRemove: { viewModel.customFields.remove(field) })
        }
    }

    var sections: some View {
        CreateEditCustomSections(addFieldButtonTitle: #localized("Add field"),
                                 contentType: viewModel.itemContentType,
                                 focusedField: $focusedField,
                                 field: { .custom($0) },
                                 sections: $viewModel.customSections,
                                 onEditSectionTitle: { viewModel.customSectionToRename = $0 },
                                 onEditFieldTitle: viewModel.requestEditCustomFieldTitle,
                                 onAddMoreField: { viewModel.requestAddCustomField(to: $0.id) })
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
