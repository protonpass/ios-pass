//
// GenericCredentialItemRow.swift
// Proton Pass - Created on 07/07/2023.
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

import Client
import DesignSystem
import Entities
import SwiftUI

struct GenericCredentialItemRow: View {
    let item: any CredentialItem
    let user: UserUiModel?
    let selectItem: (any TitledItemIdentifiable) -> Void

    var body: some View {
        Button {
            selectItem(item)
        } label: {
            if let item = item as? ItemUiModel {
                GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
                               title: item.title,
                               titleLineLimit: 2,
                               description: item.description,
                               secondaryTitle: secondaryTitle,
                               secondaryTitleColor: PassColor.textWeak)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let item = item as? ItemSearchResult {
                HStack {
                    VStack {
                        ItemSquircleThumbnail(data: item.thumbnailData())
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    VStack(alignment: .leading, spacing: 4) {
                        HighlightText(highlightableText: item.highlightableTitle,
                                      additionalTexts: additionalSearchResultTitles)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(0..<item.highlightableDetail.count, id: \.self) { index in
                                let eachDetail = item.highlightableDetail[index]
                                if !eachDetail.fullText.isEmpty {
                                    HighlightText(highlightableText: eachDetail)
                                        .font(.callout)
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                }
            }
        }
    }
}

private extension GenericCredentialItemRow {
    var secondaryTitle: String? {
        if let emailWithoutDomain = user?.emailWithoutDomain {
            "· \(emailWithoutDomain)"
        } else {
            nil
        }
    }

    var additionalSearchResultTitles: [Text] {
        if let secondaryTitle {
            [
                Text(verbatim: " "),
                Text(secondaryTitle).adaptiveForegroundStyle(PassColor.textWeak.toColor)
            ]
        } else {
            []
        }
    }
}
