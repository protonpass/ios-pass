//
// SearchView.swift
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

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocusedOnSearchBar
    @StateObject var viewModel: SearchViewModel
    @State private var safeAreaInsets = EdgeInsets.zero

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(uiColor: PassColor.backgroundNorm)
                    .ignoresSafeArea(edges: .all)
                switch viewModel.state {
                case .initializing:
                    SearchViewSkeleton()

                case .empty, .history, .noResults, .results:
                    content

                case let .error(error):
                    RetryableErrorView(errorMessage: error.localizedDescription,
                                       onRetry: { viewModel.refreshResults() })
                }
            }
            .animation(.default, value: viewModel.state)
            .onFirstAppear {
                safeAreaInsets = proxy.safeAreaInsets
                isFocusedOnSearchBar = true
                viewModel.refreshResults()
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            SearchBar(query: $viewModel.query,
                      isFocused: $isFocusedOnSearchBar,
                      placeholder: viewModel.searchBarPlaceholder,
                      onCancel: dismiss.callAsFunction)

            switch viewModel.state {
            case .empty:
                EmptySearchView()
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, safeAreaInsets.bottom + 200)

            case let .history(history):
                SearchRecentResultsView(results: history,
                                        onSelect: { viewModel.viewDetail(of: $0) },
                                        onRemove: { viewModel.removeFromHistory($0) },
                                        onClearResults: { viewModel.removeAllSearchHistory() })

            case let .noResults(query):
                if case let .all(vaultSelection) = viewModel.searchMode {
                    switch vaultSelection {
                    case .all:
                        NoSearchResultsInAllVaultView(query: query)
                    case let .precise(vault):
                        NoSearchResultsInPreciseVaultView(query: query,
                                                          vaultName: vault.name,
                                                          action: { viewModel.searchInAllVaults() })
                    case .trash:
                        NoSearchResultsInTrashView(query: query)
                    }
                } else {
                    NoSearchResultsInAllVaultView(query: query)
                }
            case let .results(itemCount, results):
                SearchResultsView(selectedType: $viewModel.selectedType,
                                  selectedSortType: $viewModel.selectedSortType,
                                  itemContextMenuHandler: viewModel.itemContextMenuHandler,
                                  itemCount: itemCount,
                                  results: results,
                                  isTrash: viewModel.isTrash,
                                  safeAreaInsets: safeAreaInsets,
                                  onScroll: { isFocusedOnSearchBar = false },
                                  onSelectItem: { viewModel.viewDetail(of: $0) },
                                  onSelectSortType: { viewModel.presentSortTypeList() })

            default:
                // Impossible cases
                EmptyView()
            }

            Spacer()
        }
        .ignoresSafeArea(edges: .bottom)
        .onFirstAppear { isFocusedOnSearchBar = true }
    }
}
