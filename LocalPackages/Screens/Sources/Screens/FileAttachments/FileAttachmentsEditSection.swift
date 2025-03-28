//
// FileAttachmentsEditSection.swift
// Proton Pass - Created on 19/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

@MainActor
public protocol FileAttachmentsEditHandler: AnyObject {
    var fileAttachmentsSectionPrimaryColor: UIColor { get }
    var fileAttachmentsSectionSecondaryColor: UIColor { get }
    var isFreeUser: Bool { get }
    var itemContentType: ItemContentType { get }

    func generateDatedFileName(prefix: String, extension: String) -> String
    func writeToTemporaryDirectory(data: Data, fileName: String) throws -> URL

    func open(attachment: FileAttachmentUiModel)
    func handleAttachment(_ url: URL)
    func handleAttachmentError(_ error: any Error)
    func showRenameAlert(attachment: FileAttachmentUiModel)
    func showDeleteAlert(attachment: FileAttachmentUiModel)
    func retryFetchAttachedFiles()
    func retryUpload(attachment: FileAttachmentUiModel)
    func deleteAllAttachments()
    func upsellFileAttachments()
}

public struct FileAttachmentsEditSection: View {
    @State private var showDeleteAllAlert = false

    private let files: [FileAttachmentUiModel]

    /// Already attached files are being fetched
    private let isFetching: Bool

    /// Error while fetching already attached files
    private let fetchError: (any Error)?

    /// Newly added files are being uploaded
    private let isUploading: Bool

    private let handler: any FileAttachmentsEditHandler

    public init(files: [FileAttachmentUiModel],
                isFetching: Bool,
                fetchError: (any Error)?,
                isUploading: Bool,
                handler: any FileAttachmentsEditHandler) {
        self.files = files
        self.isFetching = isFetching
        self.fetchError = fetchError
        self.isUploading = isUploading
        self.handler = handler
    }

    public var body: some View {
        LazyVStack {
            HStack(spacing: DesignConstant.sectionPadding) {
                ItemDetailSectionIcon(icon: IconProvider.paperClip)

                VStack(alignment: .leading) {
                    Text("Attachments")
                        .foregroundStyle(PassColor.textNorm.toColor)

                    if let fetchError {
                        RetryableErrorView(mode: .defaultHorizontal,
                                           tintColor: handler.fileAttachmentsSectionPrimaryColor,
                                           error: fetchError,
                                           onRetry: handler.retryFetchAttachedFiles)
                    }

                    if !files.isEmpty {
                        Text("\(files.count) files")
                            .font(.callout)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    } else if !isUploading, fetchError == nil {
                        Text("Upload files from your device", bundle: .module)
                            .foregroundStyle(PassColor.textWeak.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .if(isFetching) { view in
                                view.redacted(reason: .placeholder)
                            }
                            .shimmering(active: isFetching)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !files.isEmpty, !isFetching, fetchError == nil {
                    CircleButton(icon: IconProvider.trash,
                                 iconColor: handler.fileAttachmentsSectionPrimaryColor,
                                 iconDisabledColor: handler.fileAttachmentsSectionPrimaryColor,
                                 backgroundColor: handler.fileAttachmentsSectionSecondaryColor,
                                 backgroundDisabledColor: handler.fileAttachmentsSectionSecondaryColor,
                                 action: { showDeleteAllAlert.toggle() })
                        .opacityReduced(isUploading)
                }

                if handler.isFreeUser {
                    Image(uiImage: PassIcon.passSubscriptionBadge)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                }
            }

            ForEach(files) { file in
                FileAttachmentRow(mode: .edit(onOpen: { handler.open(attachment: file) },
                                              onRename: { handler.showRenameAlert(attachment: file) },
                                              onDelete: { handler.showDeleteAlert(attachment: file) },
                                              onRetryUpload: { handler.retryUpload(attachment: file) }),
                                  itemContentType: handler.itemContentType,
                                  uiModel: file,
                                  primaryTintColor: handler.fileAttachmentsSectionPrimaryColor,
                                  secondaryTintColor: handler.fileAttachmentsSectionSecondaryColor)
                    .padding(.vertical, DesignConstant.sectionPadding / 2)
                    .disabled(isUploading)
                if file != files.last {
                    PassDivider()
                }
            }

            if !isFetching, fetchError == nil {
                FileAttachmentsButton(style: .capsule, handler: handler)
                    .opacityReduced(isUploading)
            }
        }
        .animation(.default, value: files)
        .animation(.default, value: isFetching)
        .animation(.default, value: fetchError.debugDescription)
        .animation(.default, value: isUploading)
        .padding(DesignConstant.sectionPadding)
        .tint(handler.fileAttachmentsSectionPrimaryColor.toColor)
        .roundedEditableSection()
        .alert(Text("Delete all attachments?", bundle: .module),
               isPresented: $showDeleteAllAlert,
               actions: {
                   Button(role: .destructive,
                          action: { handler.deleteAllAttachments() },
                          label: { Text("Delete all", bundle: .module) })
                   Button("Cancel", role: .cancel, action: {})
               },
               message: {
                   Text("This action cannot be undone", bundle: .module)
               })
    }
}
