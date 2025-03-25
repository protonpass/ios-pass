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
import Entities
import ProtonCoreUIFoundations
import Screens
import SwiftUI
import TipKit

struct SearchView: View {
    @Binding var searchMode: SearchMode?
    let animationNamespace: Namespace.ID
    @FocusState private var isFocusedOnSearchBar
    @StateObject var viewModel: SearchViewModel
    @State private var safeAreaInsets = EdgeInsets.zero
    let refreshResults: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PassColor.backgroundNorm.toColor
                    .ignoresSafeArea(edges: .all)
                switch viewModel.state {
                case let .error(error):
                    RetryableErrorView(error: error, onRetry: viewModel.refreshResults)
                default:
                    content
                }
            }
            .animation(.default, value: viewModel.state)
            .onChange(of: refreshResults) { _ in
                viewModel.refreshResults()
            }
            .onFirstAppear {
                safeAreaInsets = proxy.safeAreaInsets
                isFocusedOnSearchBar = true
                viewModel.refreshResults()
            }
        }
    }
}

private extension SearchView {
    var content: some View {
        VStack(spacing: 0) {
            SearchBar(query: $viewModel.query,
                      isFocused: $isFocusedOnSearchBar,
                      placeholder: viewModel.searchBarPlaceholder,
                      cancelMode: .always,
                      canEdit: viewModel.state != .initializing,
                      onCancel: {
                          viewModel.cancelRefreshing()
                          searchMode = nil
                      })
                      .matchedGeometryEffect(id: SearchEffectID.searchbar.id,
                                             in: animationNamespace)

            if #available(iOS 17, *) {
                let tip = SpotlightTip()
                TipView(tip) { action in
                    if action.is(.openSettings) {
                        tip.invalidate(reason: .actionPerformed)
                        viewModel.openSettings()
                    }
                }
                .passTipView()
                .padding([.horizontal, .bottom])
            }

            switch viewModel.state {
            case .filteringResults, .initializing, .searching:
                ProgressView()
                    .padding(.top)
                Spacer()

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
                    case .all, .sharedByMe, .sharedWithMe:
                        NoSearchResultsInAllVaultView(query: query)
                    case let .precise(vault):
                        if let name = vault.vaultContent?.name {
                            NoSearchResultsInPreciseVaultView(query: query,
                                                              vaultName: name,
                                                              action: { viewModel.searchInAllVaults() })
                        }
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
                                  onSelectItem: { viewModel.viewDetail(of: $0) })

            case let .error(error):
                RetryableErrorView(error: error, onRetry: viewModel.refreshResults)
            }

            Spacer()
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: viewModel.state) { state in
            if state != .initializing {
                isFocusedOnSearchBar = true
            }
        }
    }
}
