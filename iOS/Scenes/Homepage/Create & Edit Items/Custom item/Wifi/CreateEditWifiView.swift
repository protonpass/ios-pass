//
// CreateEditWifiView.swift
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
import Screens
import SwiftUI

struct CreateEditWifiView: View {
    @StateObject private var viewModel: CreateEditWifiViewModel
    @FocusState private var focusedField: Field?
    @State private var lastFocusedField: Field?

    enum Field: CustomFieldTypes {
        case title, ssid, password
        case custom(CustomField?)

        var customField: CustomField? {
            if case let .custom(customField) = self {
                customField
            } else {
                nil
            }
        }
    }

    init(viewModel: CreateEditWifiViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                UpsellOrAttachmentsBanner(showUpgrade: viewModel.shouldUpgrade,
                                          showAttachments: viewModel.showFileAttachmentsBanner,
                                          onDismissAttachments: viewModel.dismissFileAttachmentsBanner)

                title
                ssidAndPasswordSection
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
        .navigationStackEmbeded()
        .onFirstAppear {
            if case .create = viewModel.mode {
                focusedField = .title
            }
        }
        .itemCreateEditSetUp(viewModel)
        .navigationStackEmbeded()
    }
}

private extension CreateEditWifiView {
    var title: some View {
        CreateEditItemTitleSection(title: $viewModel.title,
                                   focusedField: $focusedField,
                                   field: .title,
                                   itemContentType: viewModel.itemContentType,
                                   isEditMode: viewModel.mode.isEditMode,
                                   onSubmit: { focusedField = .ssid })
            .padding(.bottom, DesignConstant.sectionPadding / 2)
    }

    var ssidAndPasswordSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            ssidRow
            PassSectionDivider()
            passwordRow
            PassSectionDivider()
            securityRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedEditableSection()
    }

    var ssidRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Name (SSID)")
                    .editableSectionTitleText(for: viewModel.ssid)

                TextField("Add name (SSID)", text: $viewModel.ssid)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .ssid)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .onSubmit {
                        focusedField = .password
                    }
            }

            ClearTextButton(text: $viewModel.ssid)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var passwordRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Password")
                    .editableSectionTitleText(for: viewModel.password)

                SensitiveTextField(text: $viewModel.password,
                                   placeholder: #localized("Add password"),
                                   focusedField: $focusedField,
                                   field: Field.password,
                                   font: .body.monospacedFont(for: viewModel.password),
                                   onSubmit: { focusedField = nil })
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.done)
            }

            ClearTextButton(text: $viewModel.password)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var securityRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Security type")
                    .editableSectionTitleText(for: viewModel.password)

                Picker("Security type", selection: $viewModel.security) {
                    ForEach(WifiData.Security.allCases, id: \.self) { security in
                        Text(verbatim: security.displayName)
                            .id(security)
                    }
                }
                .labelsHidden()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, DesignConstant.sectionPadding)
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
