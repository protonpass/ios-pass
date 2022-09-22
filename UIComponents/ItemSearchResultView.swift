//
// ItemSearchResultView.swift
// Proton Pass - Created on 22/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import SwiftUI

public protocol ItemSearchResultProtocol {
    var icon: UIImage { get }
    var title: HighlightableText { get }
    var detail: [HighlightableText] { get }
    var vaultName: String { get }
}

public struct ItemSearchResultView: View {
    private let result: ItemSearchResultProtocol
    private let showDivider: Bool
    private let action: () -> Void

    public init(result: ItemSearchResultProtocol,
                showDivider: Bool,
                action: @escaping () -> Void) {
        self.result = result
        self.showDivider = showDivider
        self.action = action
    }

    public var body: some View {
        VStack {
            HStack {
                Button(action: action) {
                    HStack {
                        VStack {
                            Image(uiImage: result.icon)
                                .foregroundColor(Color(.label))
                                .padding(.top, -20)
                            EmptyView()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HighlightText(highlightableText: result.title)

                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(0..<result.detail.count, id: \.self) { index in
                                    let eachDetail = result.detail[index]
                                    HighlightText(highlightableText: eachDetail)
                                        .font(.callout)
                                        .foregroundColor(Color(.secondaryLabel))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }

        if showDivider {
            Divider()
        }
    }
}
