//
// SearchResultsView.swift
// Proton Pass - Created on 15/03/2023.
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

struct SearchResultsView: View {
    @Binding var selectedType: ItemContentType?
    let results: [ItemSearchResult]
    let itemCount: ItemCount
    let safeAreaInsets: EdgeInsets
    let onSelect: (ItemSearchResult) -> Void

    var body: some View {
        List {
            SearchResultChips(selectedType: $selectedType, itemCount: itemCount)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .transaction { transaction in
                    transaction.animation = nil
                }

            ForEach(results) { result in
                Button(action: {
                    onSelect(result)
                }, label: {
                    ItemSearchResultView(result: result)
                })
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Spacer()
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .frame(height: safeAreaInsets.bottom)
        }
        .listStyle(.plain)
        .animation(.default, value: results.count)
    }
}

private struct ItemSearchResultView: View {
    let result: ItemSearchResult

    var body: some View {
        HStack {
            switch result.type {
            case .alias:
                CircleButton(icon: IconProvider.alias,
                             color: ItemContentType.alias.tintColor) {}
            case .login:
                CircleButton(icon: IconProvider.keySkeleton,
                             color: ItemContentType.login.tintColor) {}
            case .note:
                CircleButton(icon: IconProvider.notepadChecklist,
                             color: ItemContentType.note.tintColor) {}
            }

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
}
