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
import Core
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct SearchResultsView: View {
    @ObservedObject private var viewModel: SearchResultsViewModel
    @Binding var selectedType: ItemContentType?
    @Binding var selectedSortType: SortType
    private let uuid = UUID()
    let safeAreaInsets: EdgeInsets
    let onScroll: () -> Void
    let onSelectItem: (ItemSearchResult) -> Void

    @State private var aliasToTrash: (any ItemTypeIdentifiable)?

    @AppStorage(Constants.QA.useSwiftUIList, store: kSharedUserDefaults)
    private var useSwiftUIList = false

    init(selectedType: Binding<ItemContentType?>,
         selectedSortType: Binding<SortType>,
         itemContextMenuHandler: ItemContextMenuHandler,
         itemCount: ItemCount,
         results: any SearchResults,
         isTrash: Bool,
         safeAreaInsets: EdgeInsets,
         onScroll: @escaping () -> Void,
         onSelectItem: @escaping (ItemSearchResult) -> Void) {
        _viewModel = .init(wrappedValue: .init(itemContextMenuHandler: itemContextMenuHandler,
                                               itemCount: itemCount,
                                               results: results,
                                               isTrash: isTrash))
        _selectedType = selectedType
        _selectedSortType = selectedSortType
        self.safeAreaInsets = safeAreaInsets
        self.onScroll = onScroll
        self.onSelectItem = onSelectItem
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchResultChips(selectedType: $selectedType, itemCount: viewModel.itemCount)
            topBarSearchInformations
            if useSwiftUIList {
                searchListItems
            } else {
                tableView
            }
        }
        .if(viewModel.aliasSyncEnabled) {
            $0.modifier(AliasTrashAlertModifier(showingTrashAliasAlert: $aliasToTrash.mappedToBool(),
                                                enabled: aliasToTrash?.aliasEnabled ?? false,
                                                disableAction: {
                                                    if let aliasToTrash {
                                                        viewModel.itemContextMenuHandler
                                                            .disableAlias(aliasToTrash)
                                                    }
                                                },
                                                trashAction: {
                                                    if let aliasToTrash {
                                                        viewModel.itemContextMenuHandler.trash(aliasToTrash)
                                                    }
                                                }))
        }
        .modifier(PermenentlyDeleteItemModifier(item: $viewModel.itemToBePermanentlyDeleted,
                                                onDisableAlias: { viewModel.disableAlias() },
                                                onDelete: { viewModel.permanentlyDelete() }))
    }

    @ViewBuilder
    private func section(for items: [ItemSearchResult], headerTitle: String) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section {
                ForEach(items) { item in
                    itemRow(for: item)
                }
            } header: {
                Text(headerTitle)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
            }
        }
    }

    private func itemRow(for item: ItemSearchResult) -> ResultRow {
        ResultRow(item: item,
                  isEditable: viewModel.isEditable(item),
                  isTrash: viewModel.isTrash,
                  aliasSyncEnabled: viewModel.aliasSyncEnabled,
                  itemContextMenuHandler: viewModel.itemContextMenuHandler,
                  itemToBePermanentlyDeleted: $viewModel.itemToBePermanentlyDeleted,
                  onSelect: { onSelectItem(item) },
                  onAliasTrash: { aliasToTrash = item })
    }
}

private extension SearchResultsView {
    var topBarSearchInformations: some View {
        let localizedString = #localized("%lld search result(s)", viewModel.results.numberOfItems)
        var attributedString = AttributedString(localizedString)

        // Apply bold to the dynamic part of the string
        if let range = attributedString.range(of: String(viewModel.results.numberOfItems)) {
            attributedString[range].font = .callout.bold()
            attributedString[range].foregroundColor = PassColor.textNorm.toColor
        }
        return HStack {
            Text(attributedString)
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)

            Spacer()

            SortTypeButton(selectedSortType: $selectedSortType)
        }
        .padding()
        .animationsDisabled()
    }
}

private extension SearchResultsView {
    @ViewBuilder
    var tableView: some View {
        let sections: [TableView<ItemSearchResult, ResultRow, Text>.Section] = switch viewModel.results {
        case let results as MostRecentSortResult<ItemSearchResult>:
            results.buckets.compactMap { bucket in
                guard !bucket.items.isEmpty else { return nil }
                return .init(type: bucket.id, title: bucket.type.title, items: bucket.items)
            }
        case let results as AlphabeticalSortResult<ItemSearchResult>:
            results.buckets.compactMap { bucket in
                guard !bucket.items.isEmpty else { return nil }
                return .init(type: bucket.letter, title: bucket.letter.character, items: bucket.items)
            }
        case let results as MonthYearSortResult<ItemSearchResult>:
            results.buckets.compactMap { bucket in
                guard !bucket.items.isEmpty else { return nil }
                return .init(type: bucket.monthYear,
                             title: bucket.monthYear.relativeString,
                             items: bucket.items)
            }
        default:
            []
        }
        let isAlphabetical = viewModel.results is AlphabeticalSortResult<ItemSearchResult>
        TableView(sections: sections,
                  configuration: .init(showSectionIndexTitles: isAlphabetical),
                  id: nil,
                  itemView: { itemRow(for: $0) },
                  headerView: { _ in nil })
    }

    var searchListItems: some View {
        ScrollViewReader { proxy in
            List {
                EmptyView()
                    .id(uuid)
                mainItemList(for: viewModel.results)
                Spacer()
                    .plainListRow()
                    .frame(height: safeAreaInsets.bottom)
            }
            .listStyle(.plain)
            .animation(.default, value: viewModel.results.hashValue)
            .simultaneousGesture(DragGesture().onChanged { _ in onScroll() })
            .onChange(of: selectedType) { _ in
                proxy.scrollTo(uuid)
            }
            .overlay {
                if selectedSortType.isAlphabetical {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy,
                                           direction: selectedSortType.sortDirection)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func mainItemList(for items: any SearchResults) -> some View {
        switch items {
        case let items as MostRecentSortResult<ItemSearchResult>:
            mostRecentItemList(items)
        case let items as AlphabeticalSortResult<ItemSearchResult>:
            alphabeticalItemList(items)
        case let items as MonthYearSortResult<ItemSearchResult>:
            monthYearItemList(items)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    func mostRecentItemList(_ result: MostRecentSortResult<ItemSearchResult>) -> some View {
        ForEach(result.buckets) { bucket in
            section(for: bucket.items, headerTitle: bucket.type.title)
        }
    }

    func alphabeticalItemList(_ result: AlphabeticalSortResult<ItemSearchResult>) -> some View {
        ForEach(result.buckets, id: \.letter) { bucket in
            section(for: bucket.items, headerTitle: bucket.letter.character)
                .id(bucket.letter.character)
        }
    }

    func monthYearItemList(_ result: MonthYearSortResult<ItemSearchResult>) -> some View {
        ForEach(result.buckets, id: \.monthYear) { bucket in
            section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
        }
    }
}

private struct ResultRow: View {
    let item: ItemSearchResult
    let isEditable: Bool
    let isTrash: Bool
    let aliasSyncEnabled: Bool
    let itemContextMenuHandler: ItemContextMenuHandler
    @Binding var itemToBePermanentlyDeleted: (any ItemTypeIdentifiable)?
    let onSelect: () -> Void
    let onAliasTrash: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ItemSearchResultView(result: item)
                .itemContextMenu(item: item,
                                 isTrashed: isTrash,
                                 isEditable: isEditable,
                                 aliasSyncEnabled: aliasSyncEnabled,
                                 onPermanentlyDelete: { itemToBePermanentlyDeleted = item },
                                 onAliasTrash: onAliasTrash,
                                 handler: itemContextMenuHandler)
        }
        .plainListRow()
        .padding(.horizontal)
        .padding(.vertical, 12)
        .modifier(ItemSwipeModifier(itemToBePermanentlyDeleted: $itemToBePermanentlyDeleted,
                                    item: item,
                                    isEditMode: false,
                                    isTrashed: isTrash,
                                    isEditable: isEditable,
                                    itemContextMenuHandler: itemContextMenuHandler,
                                    aliasSyncEnabled: aliasSyncEnabled))
    }
}
