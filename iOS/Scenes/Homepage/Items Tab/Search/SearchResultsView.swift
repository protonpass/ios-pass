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
    @State private var itemToBePermanentlyDeleted: ItemTypeIdentifiable?
    @Binding var selectedType: ItemContentType?
    @Binding var selectedSortType: SortType
    private let uuid = UUID()
    let itemContextMenuHandler: ItemContextMenuHandler
    let itemCount: ItemCount
    let results: [ItemSearchResult]
    let isTrash: Bool
    let safeAreaInsets: EdgeInsets
    let onScroll: () -> Void
    let onSelectItem: (ItemSearchResult) -> Void
    let onSelectSortType: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SearchResultChips(selectedType: $selectedType, itemCount: itemCount)

            HStack {
                Text("\(results.count)")
                    .font(.callout)
                    .fontWeight(.bold) +
                Text(" result(s)")
                    .font(.callout)
                    .foregroundColor(.textWeak)

                Spacer()

                SortTypeButton(selectedSortType: $selectedSortType, action: onSelectSortType)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .animationsDisabled()

            ScrollViewReader { proxy in
                List {
                    EmptyView()
                        .id(uuid)
                    itemList(results)
                    Spacer()
                        .listRowSeparator(.hidden)
                        .listRowInsets(.zero)
                        .listRowBackground(Color.clear)
                        .frame(height: safeAreaInsets.bottom)
                }
                .listStyle(.plain)
                .animation(.default, value: results.hashValue)
                .gesture(DragGesture().onChanged { _ in onScroll() })
                .onChange(of: selectedType) { _ in
                    proxy.scrollTo(uuid)
                }
            }
        }
    }

    @ViewBuilder
    private func itemList(_ items: [ItemSearchResult]) -> some View {
        switch selectedSortType {
        case .mostRecent:
            itemList(items.mostRecentSortResult())
        case .alphabetical:
            itemList(items.alphabeticalSortResult())
        case .newestToOldest:
            itemList(items.monthYearSortResult(direction: .descending))
        case .oldestToNewest:
            itemList(items.monthYearSortResult(direction: .ascending))
        }
    }

    @ViewBuilder
    private func itemList(_ result: MostRecentSortResult<ItemSearchResult>) -> some View {
        section(for: result.today, headerTitle: "Today")
        section(for: result.yesterday, headerTitle: "Yesterday")
        section(for: result.last7Days, headerTitle: "Last week")
        section(for: result.last14Days, headerTitle: "Last two weeks")
        section(for: result.last30Days, headerTitle: "Last 30 days")
        section(for: result.last60Days, headerTitle: "Last 60 days")
        section(for: result.last90Days, headerTitle: "Last 90 days")
        section(for: result.others, headerTitle: "More than 90 days")
    }

    private func itemList(_ result: AlphabeticalSortResult<ItemSearchResult>) -> some View {
        ForEach(result.buckets, id: \.letter) { bucket in
            section(for: bucket.items, headerTitle: bucket.letter.character)
                .id(bucket.letter.character)
        }
    }

    private func itemList(_ result: MonthYearSortResult<ItemSearchResult>) -> some View {
        ForEach(result.buckets, id: \.monthYear) { bucket in
            section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
        }
    }

    @ViewBuilder
    private func section(for items: [ItemSearchResult], headerTitle: String) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items, id: \.hashValue) { item in
                    itemRow(for: item)
                }
            }, header: {
                Text(headerTitle)
            })
        }
    }

    @ViewBuilder
    private func itemRow(for item: ItemSearchResult) -> some View {
        let permanentlyDeleteBinding = Binding<Bool>(get: {
            itemToBePermanentlyDeleted != nil
        }, set: { newValue in
            if !newValue {
                itemToBePermanentlyDeleted = nil
            }
        })

        Button(action: {
            onSelectItem(item)
        }, label: {
            ItemSearchResultView(result: item)
        })
        .listRowSeparator(.hidden)
        .listRowInsets(.zero)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .listRowBackground(Color.clear)
        .modifier(ItemSwipeModifier(
            itemToBePermanentlyDeleted: $itemToBePermanentlyDeleted,
            item: item,
            isTrashed: isTrash,
            itemContextMenuHandler: itemContextMenuHandler))
        .itemContextMenu(item: item,
                         isTrashed: isTrash,
                         onPermanentlyDelete: { itemToBePermanentlyDeleted = item },
                         handler: itemContextMenuHandler)
        .modifier(PermenentlyDeleteItemModifier(
            isShowingAlert: permanentlyDeleteBinding,
            onDelete: {
                if let itemToBePermanentlyDeleted {
                    itemContextMenuHandler.deletePermanently(itemToBePermanentlyDeleted)
                }
            }))
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
                    .animationsDisabled()

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(0..<result.detail.count, id: \.self) { index in
                        let eachDetail = result.detail[index]
                        if !eachDetail.fullText.isEmpty {
                            HighlightText(highlightableText: eachDetail)
                                .font(.callout)
                                .foregroundColor(Color(.secondaryLabel))
                                .lineLimit(1)
                                .animationsDisabled()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }
}
