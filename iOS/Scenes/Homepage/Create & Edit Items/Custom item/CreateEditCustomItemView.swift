//
// CreateEditCustomItemView.swift
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

struct CreateEditCustomItemView: View {
    @StateObject private var viewModel: CreateEditCustomItemViewModel
    @FocusState private var focusedField: Field?
    @State private var lastFocusedField: Field?

    enum Field: CustomFieldTypes {
        case title, note
        case custom(CustomField?)

        var customField: CustomField? {
            if case let .custom(customField) = self {
                customField
            } else {
                nil
            }
        }
    }

    init(viewModel: CreateEditCustomItemViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                UpsellOrAttachmentsBanner(showUpgrade: viewModel.shouldUpgrade,
                                          showAttachments: !viewModel.dismissedFileAttachmentsBanner,
                                          onDismissAttachments: viewModel.dismissFileAttachmentsBanner)

                title
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

                PassSectionDivider()

                NoteEditSection(note: $viewModel.note,
                                focusedField: $focusedField,
                                field: .note)

                FileAttachmentsEditSection(files: viewModel.fileUiModels,
                                           isFetching: viewModel.isFetchingAttachedFiles,
                                           fetchError: viewModel.fetchAttachedFilesError,
                                           isUploading: viewModel.isUploadingFile,
                                           handler: viewModel)
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
        .onFirstAppear {
            if case .create = viewModel.mode {
                focusedField = .title
            }
        }
        .navigationStackEmbeded()
    }
}

private extension CreateEditCustomItemView {
    var title: some View {
        CreateEditItemTitleSection(title: $viewModel.title,
                                   focusedField: $focusedField,
                                   field: .title,
                                   itemContentType: viewModel.itemContentType,
                                   isEditMode: viewModel.mode.isEditMode,
                                   onSubmit: nil)
            .padding(.bottom, DesignConstant.sectionPadding / 2)
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

struct UpsellOrAttachmentsBanner: View {
    let showUpgrade: Bool
    let showAttachments: Bool
    let onDismissAttachments: () -> Void

    var body: some View {
        if showUpgrade {
            Text("Upgrade to create custom items")
                .padding()
                .foregroundStyle(PassColor.textNorm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PassColor.interactionNormMinor1)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            FileAttachmentsBanner(isShown: showAttachments,
                                  onTap: onDismissAttachments,
                                  onClose: onDismissAttachments)
        }
    }
}
