//
// CredentialsView.swift
// Proton Pass - Created on 27/09/2022.
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

import Client
import Core
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CredentialsView: View {
    @StateObject private var viewModel: CredentialsViewModel
    @State private var isLocked: Bool
    private let preferences: Preferences

    init(viewModel: CredentialsViewModel, preferences: Preferences) {
        _viewModel = .init(wrappedValue: viewModel)
        _isLocked = .init(wrappedValue: preferences.localAuthenticationEnabled)
        self.preferences = preferences
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLocked {
                    AppLockedView(preferences: preferences,
                                  delayed: true,
                                  onSuccess: { isLocked = false },
                                  onFailure: viewModel.handleAuthenticationFailure)
                } else {
                    switch viewModel.state {
                    case .loading:
                        ProgressView()

                    case let .loaded(result, state):
                        if result.isEmpty {
                            NoCredentialsView()
                        } else {
                            VStack(spacing: 0) {
                                SwiftUISearchBar(placeholder: "Search...",
                                                 showsCancelButton: false,
                                                 shouldBecomeFirstResponder: false,
                                                 onSearch: viewModel.search,
                                                 onCancel: {})

                                switch state {
                                case .idle:
                                    itemList(matchedItems: result.matchedItems,
                                             notMatchedItems: result.notMatchedItems)

                                case .searching:
                                    ProgressView()

                                case .noSearchResults:
                                    NoSearchResultsView()

                                case .searchResults(let searchResults):
                                    searchResultsList(searchResults)
                                }

                                Spacer()
                            }
                            .animation(.default, value: state)
                        }

                    case .error(let error):
                        RetryableErrorView(errorMessage: error.messageForTheUser,
                                           onRetry: viewModel.fetchItems)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Autofill password")
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: viewModel.cancel) {
                Text("Cancel")
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.showCreateLoginView) {
                Image(uiImage: IconProvider.plus)
                    .foregroundColor(.primary)
            }
        }
    }

    private func itemList(matchedItems: [ItemListUiModel],
                          notMatchedItems: [ItemListUiModel]) -> some View {
        List {
            Section(content: {
                if matchedItems.isEmpty {
                    Text("No suggestions")
                        .font(.callout.italic())
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(matchedItems) { item in
                        view(for: item)
                    }
                    .listRowSeparator(.hidden)
                }
            }, header: {
                header(text: "Suggestions for \(viewModel.urls.first?.host ?? "")")
            })

            Section(content: {
                if notMatchedItems.isEmpty {
                    Text("No other items")
                        .font(.callout.italic())
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(notMatchedItems) { item in
                        view(for: item)
                    }
                    .listRowSeparator(.hidden)
                }
            }, header: {
                header(text: "Others items")
            })
        }
        .listStyle(.plain)
        .animation(.default, value: matchedItems.count + notMatchedItems.count)
        .padding(.bottom, 44) // Otherwise content goes below the visible area. SwiftUI bug?
    }

    private func view(for item: ItemListUiModel) -> some View {
        GenericItemView(
            item: item,
            action: { viewModel.select(item: item) },
            trailingView: { EmptyView() })
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
    }

    private func header(text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(.secondary)
            .font(.callout)
    }

    private func searchResultsList(_ results: [ItemSearchResult]) -> some View {
        List {
            ForEach(results) { result in
                ItemSearchResultView(result: result,
                                     action: { viewModel.select(item: result) })
            }
        }
        .listStyle(.plain)
        .animation(.default, value: results.count)
    }
}
