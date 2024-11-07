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

    @State private var showingTrashAliasAlert = false
    @State private var aliasToTrash: (any ItemTypeIdentifiable)?

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
//            searchListItems
        }
        .if(viewModel.aliasSyncEnabled) {
            $0.modifier(AliasTrashAlertModifier(showingTrashAliasAlert: $showingTrashAliasAlert,
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

    @ViewBuilder
    private func itemRow(for item: ItemSearchResult) -> some View {
        let isEditable = viewModel.isEditable(item)
        Button(action: {
            onSelectItem(item)
        }, label: {
            ItemSearchResultView(result: item)
                .itemContextMenu(item: item,
                                 isTrashed: viewModel.isTrash,
                                 isEditable: isEditable,
                                 aliasSyncEnabled: viewModel.aliasSyncEnabled,
                                 onPermanentlyDelete: { viewModel.itemToBePermanentlyDeleted = item },
                                 onAliasTrash: {
                                     aliasToTrash = item
                                     showingTrashAliasAlert.toggle()
                                 },
                                 handler: viewModel.itemContextMenuHandler)
        })
        .plainListRow()
        .padding(.horizontal)
        .padding(.vertical, 12)
        .modifier(ItemSwipeModifier(itemToBePermanentlyDeleted: $viewModel.itemToBePermanentlyDeleted,
                                    item: item,
                                    isEditMode: false,
                                    isTrashed: viewModel.isTrash,
                                    isEditable: isEditable,
                                    itemContextMenuHandler: viewModel.itemContextMenuHandler,
                                    aliasSyncEnabled: viewModel.aliasSyncEnabled))
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
