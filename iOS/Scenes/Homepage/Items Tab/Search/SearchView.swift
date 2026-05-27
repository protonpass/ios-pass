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
    let animationNamespace: Namespace.ID
    @FocusState private var isFocusedOnSearchBar
    @StateObject var viewModel = SearchViewModel()
    @State private var safeAreaInsets = EdgeInsets.zero
    let onCancel: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                content(showCustomSearchBar: false)
                    .searchable(text: $viewModel.query, prompt: viewModel.searchBarPlaceholder)
            }
        } else {
            GeometryReader { proxy in
                content(showCustomSearchBar: true)
                    .ignoresSafeArea(edges: .bottom)
                    .onFirstAppear {
                        safeAreaInsets = proxy.safeAreaInsets
                        isFocusedOnSearchBar = true
                    }
            }
        }
    }
}

private extension SearchView {
    func content(showCustomSearchBar: Bool) -> some View {
        VStack(spacing: 0) {
            if showCustomSearchBar {
                SearchBar(query: $viewModel.query,
                          isFocused: $isFocusedOnSearchBar,
                          placeholder: viewModel.searchBarPlaceholder,
                          cancelMode: .always,
                          canEdit: viewModel.state != .initializing,
                          onCancel: {
                              viewModel.cancelRefreshing()
                              onCancel()
                          })
                          .matchedGeometryEffect(id: SearchEffectID.searchbar.id,
                                                 in: animationNamespace)
            } else {
                Text("Search")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .animationsDisabled()
            }

            let tip = SpotlightTip()
            TipView(tip) { action in
                if action.is(.openSettings) {
                    tip.invalidate(reason: .actionPerformed)
                    viewModel.openSettings()
                }
            }
            .passTipView()
            .padding([.horizontal, .bottom])

            switch viewModel.state {
            case .filteringResults, .initializing, .searching:
                Spacer()
                ProgressView()
                    .controlSize(.extraLarge)
                    .padding(.top)

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
                NoSearchResultsView(query: query)

            case let .results(results):
                SearchResultsView(selectedType: $viewModel.selectedType,
                                  selectedSortType: $viewModel.selectedSortType,
                                  vaultSearchSelection: $viewModel.vaultSearchSelection,
                                  itemContextMenuHandler: viewModel.itemContextMenuHandler,
                                  results: results,
                                  safeAreaInsets: safeAreaInsets,
                                  onScroll: { isFocusedOnSearchBar = false },
                                  onSelectItem: { viewModel.viewDetail(of: $0) })

            case let .error(error):
                RetryableErrorView(error: error, onRetry: viewModel.refreshResults)
            }

            Spacer()
        }
        .fullSheetBackground(PassColor.backgroundNorm)
        .animation(.default, value: viewModel.state)
        .onChange(of: viewModel.state) {
            if viewModel.state != .initializing {
                isFocusedOnSearchBar = true
            }
        }
        .task {
            viewModel.resetState()
            viewModel.refreshResults()
        }
    }
}
