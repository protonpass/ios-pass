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

public struct FileAttachmentsEditSection: View {
    let files: [FileAttachment]
    let isUploading: Bool
    let primaryTintColor: UIColor
    let secondaryTintColor: UIColor
    let onDelete: () -> Void
    let onSelect: (FileAttachmentMethod) -> Void

    public init(files: [FileAttachment],
                isUploading: Bool,
                primaryTintColor: UIColor,
                secondaryTintColor: UIColor,
                onDelete: @escaping () -> Void,
                onSelect: @escaping (FileAttachmentMethod) -> Void) {
        self.files = files
        self.isUploading = isUploading
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
        self.onDelete = onDelete
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack {
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
                                 iconColor: primaryTintColor,
                                 iconDisabledColor: primaryTintColor,
                                 backgroundColor: secondaryTintColor,
                                 backgroundDisabledColor: secondaryTintColor)
                        .opacityReduced(isUploading)
                }
            }

            ForEach(files) { file in
                Text(file.metadata.name)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if file != files.last {
                    PassDivider()
                }
            }

            FileAttachmentsButton(style: .capsule,
                                  iconColor: primaryTintColor,
                                  backgroundColor: secondaryTintColor,
                                  onSelect: onSelect)
                .opacityReduced(isUploading)
        }
        .animation(.default, value: files)
        .animation(.default, value: isUploading)
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
    }
}
