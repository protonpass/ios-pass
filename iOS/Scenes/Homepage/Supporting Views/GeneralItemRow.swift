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
    @Environment(\.isEnabled) private var isEnabled
    let thumbnailView: ThumbnailView
    let title: String
    let titleLineLimit: Int
    let secondaryTitle: String?
    let secondaryTitleColor: UIColor?
    let description: String?
    let descriptionLineLimit: Int

    init(@ViewBuilder thumbnailView: () -> ThumbnailView,
         title: String,
         titleLineLimit: Int = 2,
         description: String?,
         descriptionLineLimit: Int = 1,
         secondaryTitle: String? = nil,
         secondaryTitleColor: UIColor? = nil) {
        self.thumbnailView = thumbnailView()
        self.title = title
        self.titleLineLimit = titleLineLimit
        self.description = description
        self.descriptionLineLimit = descriptionLineLimit
        self.secondaryTitle = secondaryTitle
        self.secondaryTitleColor = secondaryTitleColor
    }

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack {
                Spacer()
                thumbnailView
                    .frame(width: 40)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(titleTexts)
                    .lineLimit(titleLineLimit)
                    .truncationMode(secondaryTitle == nil ? .tail : .middle)
                    .fixedSize(horizontal: false, vertical: true)

                if let description, !description.isEmpty {
                    Text(description)
                        .font(.callout)
                        .lineLimit(descriptionLineLimit)
                        .minimumScaleFactor(descriptionLineLimit > 1 ? 0.75 : 1.0)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
    }

    var titleTexts: [Text] {
        var result = [Text]()
        let titleText = Text(title)
            .adaptiveForegroundStyle((isEnabled ? PassColor.textNorm : PassColor.textWeak).toColor)
        result.append(titleText)
        result.append(Text(verbatim: " "))
        if let secondaryTitle {
            let secondaryText = Text(secondaryTitle)
                .adaptiveForegroundStyle((isEnabled ?
                        (secondaryTitleColor ?? PassColor.textNorm) : PassColor.textWeak).toColor)
            result.append(secondaryText)
        }
        return result
    }
}
