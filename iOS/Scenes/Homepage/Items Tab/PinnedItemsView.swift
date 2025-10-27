//
// PinnedItemsView.swift
// Proton Pass - Created on 05/12/2023.
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
import Entities
import SwiftUI

struct PinnedItemsView: View {
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    let pinnedItems: [ItemUiModel]
    let onSearch: () -> Void
    let action: (ItemUiModel) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 8) {
                ForEach(pinnedItems) { item in
                    Button {
                        action(item)
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            ItemSquircleThumbnail(data: item.thumbnailData(),
                                                  size: .small,
                                                  alternativeBackground: true)
                            Text(item.title)
                                .lineLimit(1)
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .padding(.trailing, 8)
                        }
                        .padding(8)
                        .frame(maxWidth: 165, alignment: .leading)
                        .background(item.type.normMinor1Color.toColor)
                        .cornerRadius(16)
                    }
                }

                if pinnedItems.count >= 5 {
                    Button {
                        onSearch()
                    } label: {
                        Text("See all")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                            .padding(.trailing, 8)
                    }
                }
            }
            .padding(.horizontal, showButtonShapes ? 0 : nil)
            .padding(.vertical, showButtonShapes ? 4 : 12)
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
        }
    }
}
