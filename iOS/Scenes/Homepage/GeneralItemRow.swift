//
// GeneralItemRow.swift
// Proton Pass - Created on 06/03/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import SwiftUI

struct GeneralItemRow<ThumbnailView: View>: View {
    let thumbnailView: ThumbnailView
    let title: String
    let secondaryTitle: String?
    let secondaryTitleColor: UIColor?
    let description: String?
    let descriptionLineLimit: Int

    init(@ViewBuilder thumbnailView: () -> ThumbnailView,
         title: String,
         description: String?,
         descriptionLineLimit: Int = 1,
         secondaryTitle: String? = nil,
         secondaryTitleColor: UIColor? = nil) {
        self.thumbnailView = thumbnailView()
        self.title = title
        self.description = description
        self.descriptionLineLimit = descriptionLineLimit
        self.secondaryTitle = secondaryTitle
        self.secondaryTitleColor = secondaryTitleColor
    }

    var body: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            VStack {
                Spacer()
                thumbnailView
                    .frame(width: 40)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
                    if let secondaryTitle {
                        Text(secondaryTitle)
                            .foregroundColor(Color(uiColor: secondaryTitleColor ?? PassColor.textNorm))
                    }
                }

                if let description, !description.isEmpty {
                    Text(description)
                        .font(.callout)
                        .lineLimit(descriptionLineLimit)
                        .minimumScaleFactor(descriptionLineLimit > 1 ? 0.75 : 1.0)
                        .foregroundColor(Color(uiColor: PassColor.textWeak))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
