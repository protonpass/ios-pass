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

@preconcurrency import Combine
import DesignSystem
import DocScanner
import Entities
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreateEditNoteView: View {
    @StateObject private var viewModel: CreateEditNoteViewModel
    @FocusState private var focusedField: Field?
    @State private var lastFocusedField: Field?
    @Namespace private var fileAttachmentsID

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

    init(viewModel: CreateEditNoteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometryReaderProxy in
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        mainContent(size: geometryReaderProxy.size,
                                    proxy: scrollViewProxy)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            // The below modifiers must be applied to the outer most view container
            // otherwise we would have bugs like "Add more" button not responsible
            .toolbar {
                CreateEditKeyboardToolbar(lastFocusedField: $lastFocusedField,
                                          focusedField: focusedField,
                                          onOpenCodeScanner: viewModel.openCodeScanner,
                                          onPasteTotpUri: { viewModel.handlePastingTotpUri(customField: $0) })
            }
            .onFirstAppear {
                if case .create = viewModel.mode {
                    focusedField = .title
                }
            }
            .itemCreateEditSetUp(viewModel)
            .scannerSheet(isPresented: $viewModel.isShowingScanner,
                          interpreter: viewModel.interpretor,
                          resultStream: viewModel.scanResponsePublisher)
        }
    }
}

private extension CreateEditNoteView {
    func mainContent(size: CGSize, proxy: ScrollViewProxy) -> some View {
        VStack {
            FileAttachmentsBanner(isShown: !viewModel.dismissedFileAttachmentsBanner,
                                  onTap: {
                                      viewModel.dismissFileAttachmentsBanner()
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                          proxy.scrollTo(fileAttachmentsID, anchor: .bottom)
                                      }
                                  },
                                  onClose: { viewModel.dismissFileAttachmentsBanner() })

            CreateEditItemTitleSection(title: $viewModel.title,
                                       focusedField: $focusedField,
                                       field: .title,
                                       itemContentType: viewModel.itemContentType,
                                       isEditMode: viewModel.mode.isEditMode,
                                       onSubmit: { focusedField = .note })

            EditableTextViewWithPlaceholder(text: $viewModel.note,
                                            config: .init(minHeight: size.height / 2),
                                            placeholder: #localized("Note"))
                .padding(DesignConstant.sectionPadding)
                .roundedEditableSection()
                .focused($focusedField, equals: .note)

            if viewModel.customTypeEnabled {
                EditCustomFieldSections(focusedField: $focusedField,
                                        focusedCustomField: viewModel.recentlyAddedOrEditedField,
                                        contentType: .note,
                                        fields: $viewModel.customFields,
                                        canAddMore: viewModel.canAddMoreCustomFields,
                                        onAddMore: { viewModel.requestAddCustomField(to: nil) },
                                        onEditTitle: viewModel.requestEditCustomFieldTitle,
                                        onUpgrade: { viewModel.upgrade() })
            }

            FileAttachmentsEditSection(files: viewModel.fileUiModels,
                                       isFetching: viewModel.isFetchingAttachedFiles,
                                       fetchError: viewModel.fetchAttachedFilesError,
                                       isUploading: viewModel.isUploadingFile,
                                       handler: viewModel)
                .id(fileAttachmentsID)
        }
        .padding()
    }
}
