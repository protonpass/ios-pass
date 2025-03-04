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
import Screens
import SwiftUI

struct CreateEditCustomItemView: View {
    @StateObject private var viewModel: CreateEditCustomItemViewModel
    @FocusState private var focusedField: Field?

    enum Field: CustomFieldTypes {
        case title
        case custom(CustomFieldUiModel?)
    }

    init(viewModel: CreateEditCustomItemViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                title
                fields

                AddCustomFieldAndSectionView(onAddField: viewModel.addCustomField,
                                             onAddSection: viewModel.customSectionUiModels.isEmpty ?
                                                 { print("Add section") } : nil)

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
}
