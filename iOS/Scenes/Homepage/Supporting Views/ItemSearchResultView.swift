//
// ItemSearchResultView.swift
// Proton Pass - Created on 01/03/2024.
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

import Client
import DesignSystem
import SwiftUI

struct ItemSearchResultView: View, Equatable {
    let result: ItemSearchResult

    var body: some View {
        HStack {
            VStack {
                ItemSquircleThumbnail(data: result.thumbnailData(),
                                      isEnabled: result.aliasEnabled)
            }
            .frame(maxHeight: .infinity, alignment: .top)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if let vaultContent = result.vault?.vaultContent {
                        Image(uiImage: vaultContent.vaultSmallIcon)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(PassColor.textWeak)
                            .frame(width: 12, height: 12)
                    }
                    HighlightText(highlightableText: result.highlightableTitle)
                        .foregroundStyle(PassColor.textNorm)
                        .animationsDisabled()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(0..<result.highlightableDetail.count, id: \.self) { index in
                        let eachDetail = result.highlightableDetail[index]
                        if !eachDetail.fullText.isEmpty {
                            HighlightText(highlightableText: eachDetail)
                                .font(.callout)
                                .foregroundStyle(PassColor.textWeak)
                                .lineLimit(1)
                                .animationsDisabled()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(.rect)
    }

    nonisolated static func == (lhs: ItemSearchResultView, rhs: ItemSearchResultView) -> Bool {
        lhs.result == rhs.result // or whatever is equal
    }
}
