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
    let item: CredentialItem
    let user: UserUiModel?
    let selectItem: (any TitledItemIdentifiable) -> Void

    var body: some View {
        Button {
            selectItem(item)
        } label: {
            switch item {
            case let .uiModel(uiModel):
                GeneralItemRow(thumbnailView: {
                                   ItemSquircleThumbnail(data: uiModel.thumbnailData(),
                                                         pinned: uiModel.pinned)
                               },
                               title: uiModel.title,
                               titleLineLimit: 2,
                               description: uiModel.description,
                               secondaryTitle: secondaryTitle,
                               secondaryTitleColor: PassColor.textWeak,
                               hasTotp: uiModel.hasTotpUri,
                               isShared: uiModel.isShared)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case let .searchResult(result):
                HStack {
                    VStack {
                        ItemSquircleThumbnail(data: result.thumbnailData(),
                                              pinned: result.pinned)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    VStack(alignment: .leading, spacing: 4) {
                        HighlightText(highlightableText: result.highlightableTitle,
                                      additionalTexts: additionalSearchResultTitles)
                            .foregroundStyle(PassColor.textNorm.toColor)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(0..<result.highlightableDetail.count, id: \.self) { index in
                                let eachDetail = result.highlightableDetail[index]
                                if !eachDetail.fullText.isEmpty {
                                    HighlightText(highlightableText: eachDetail)
                                        .font(.callout)
                                        .foregroundStyle(PassColor.textWeak.toColor)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
