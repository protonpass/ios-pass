//
// ItemSearchResultView.swift
// Proton Pass - Created on 13/03/2023.
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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

public struct ItemSearchResultView<TrailingView: View>: View {
    private let result: ItemSearchResultProtocol
    private let action: () -> Void
    private let trailingView: TrailingView

    public init(result: ItemSearchResultProtocol,
                action: @escaping () -> Void,
                @ViewBuilder trailingView: () -> TrailingView = { EmptyView() }) {
        self.result = result
        self.action = action
        self.trailingView = trailingView()
    }

    public var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    ZStack {
                        Color(.passBrand).opacity(0.1)
                        Image(uiImage: IconProvider.note)
                            .resizable()
                            .foregroundColor(Color(.passBrand))
                            .padding(7.5)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        HighlightText(highlightableText: result.title)

                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(0..<result.detail.count, id: \.self) { index in
                                let eachDetail = result.detail[index]
                                if !eachDetail.fullText.isEmpty {
                                    HighlightText(highlightableText: eachDetail)
                                        .font(.callout)
                                        .foregroundColor(Color(.secondaryLabel))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            trailingView
        }
    }
}
