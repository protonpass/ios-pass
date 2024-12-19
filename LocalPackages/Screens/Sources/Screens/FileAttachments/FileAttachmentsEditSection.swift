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
import UseCases

@MainActor
public protocol FileAttachmentsEditHandler: AnyObject {
    var fileAttachmentsSectionPrimaryColor: UIColor { get }
    var fileAttachmentsSectionSecondaryColor: UIColor { get }
    var itemContentType: ItemContentType { get }

    func generateDatedFileName(prefix: String, extension: String) -> String
    func writeToTemporaryDirectory(data: Data, fileName: String) throws -> URL

    func handleAttachment(_ url: URL)
    func handleAttachmentError(_ error: any Error)
    func rename(attachment: FileAttachment, newName: String)
    func retryUpload(attachment: FileAttachment)
    func delete(attachment: FileAttachment)
    func deleteAllAttachments()
}

public struct FileAttachmentsEditSection: View {
    @State private var showDeleteAllAlert = false

    private let files: [FileAttachment]
    private let isUploading: Bool
    private let handler: any FileAttachmentsEditHandler

    public init(files: [FileAttachment],
                isUploading: Bool,
                handler: any FileAttachmentsEditHandler) {
        self.files = files
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

                    if !files.isEmpty {
                        Text("\(files.count) files")
                            .font(.callout)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    } else if !isUploading {
                        Text("Upload files from your device")
                            .foregroundStyle(PassColor.textWeak.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !files.isEmpty {
                    CircleButton(icon: IconProvider.trash,
                                 iconColor: handler.fileAttachmentsSectionPrimaryColor,
                                 iconDisabledColor: handler.fileAttachmentsSectionPrimaryColor,
                                 backgroundColor: handler.fileAttachmentsSectionSecondaryColor,
                                 backgroundDisabledColor: handler.fileAttachmentsSectionSecondaryColor,
                                 action: { showDeleteAllAlert.toggle() })
                        .opacityReduced(isUploading)
                }
            }

            ForEach(files) { file in
                FileAttachmentRow(mode: .edit, file: file, handler: handler)
                    .padding(.vertical, DesignConstant.sectionPadding / 2)
                    .disabled(isUploading)
                if file != files.last {
                    PassDivider()
                }
            }

            FileAttachmentsButton(style: .capsule, handler: handler)
                .opacityReduced(isUploading)
        }
        .animation(.default, value: files)
        .animation(.default, value: isUploading)
        .padding(DesignConstant.sectionPadding)
        .tint(handler.fileAttachmentsSectionPrimaryColor.toColor)
        .roundedEditableSection()
        .alert("Delete all attachments?",
               isPresented: $showDeleteAllAlert,
               actions: {
                   Button("Delete all",
                          role: .destructive,
                          action: { handler.deleteAllAttachments() })
                   Button("Cancel", role: .cancel, action: {})
               },
               message: {
                   Text("This action cannot be undone")
               })
    }
}
