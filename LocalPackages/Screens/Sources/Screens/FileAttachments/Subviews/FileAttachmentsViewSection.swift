//
// FileAttachmentsViewSection.swift
// Proton Pass - Created on 16/12/2024.
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
public protocol FileAttachmentsViewHandler: AnyObject {
    var fileAttachmentsSectionPrimaryColor: Color { get }
    var fileAttachmentsSectionSecondaryColor: Color { get }

    func retryFetchingAttachments()
    func open(_ file: FileAttachmentUiModel)
    func save(_ file: FileAttachmentUiModel)
    func share(_ file: FileAttachmentUiModel)
}

public struct FileAttachmentsViewSection: View {
    private let files: [FileAttachmentUiModel]
    /// Already attached files are being fetched
    private let isFetching: Bool
    /// Error while fetching already attached files
    private let fetchError: (any Error)?
    private let borderColor: Color?
    private let handler: any FileAttachmentsViewHandler

    public init(files: [FileAttachmentUiModel],
                isFetching: Bool,
                fetchError: (any Error)?,
                borderColor: Color? = nil,
                handler: any FileAttachmentsViewHandler) {
        self.files = files
        self.isFetching = isFetching
        self.fetchError = fetchError
        self.borderColor = borderColor
        self.handler = handler
    }

    public var body: some View {
        LazyVStack {
            HStack(spacing: DesignConstant.sectionPadding) {
                ItemDetailSectionIcon(icon: IconProvider.paperClip)

                VStack(alignment: .leading) {
                    Text("Attachments", bundle: .module)
                        .foregroundStyle(PassColor.textNorm)

                    if isFetching {
                        ProgressView()
                            .controlSize(.mini)
                    }

                    if let fetchError {
                        RetryableErrorView(mode: .defaultHorizontal,
                                           tintColor: handler.fileAttachmentsSectionPrimaryColor,
                                           error: fetchError,
                                           onRetry: handler.retryFetchingAttachments)
                    }

                    if !files.isEmpty {
                        Text("\(files.count) files", bundle: .module)
                            .font(.callout)
                            .foregroundStyle(PassColor.textWeak)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(files) { file in
                FileAttachmentRow(mode: .view(onOpen: { handler.open(file) },
                                              onSave: { handler.save(file) },
                                              onShare: { handler.share(file) }),
                                  uiModel: file,
                                  primaryTintColor: handler.fileAttachmentsSectionPrimaryColor,
                                  secondaryTintColor: handler.fileAttachmentsSectionSecondaryColor)
                    .padding(.vertical, DesignConstant.sectionPadding / 2)
                if file != files.last {
                    PassDivider()
                }
            }
        }
        .animation(.default, value: files)
        .animation(.default, value: isFetching)
        .animation(.default, value: fetchError.debugDescription)
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection(borderColor: borderColor ?? PassColor.inputBorderNorm)
    }
}
