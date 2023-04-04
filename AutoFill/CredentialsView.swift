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
    @State private var query = ""
    @State private var isLocked: Bool
    @State private var selectedNotMatchedItem: TitledItemIdentifiable?
    private let preferences: Preferences

    init(viewModel: CredentialsViewModel, preferences: Preferences) {
        _viewModel = .init(wrappedValue: viewModel)
        _isLocked = .init(wrappedValue: preferences.biometricAuthenticationEnabled)
        self.preferences = preferences
    }

    var body: some View {
        let isShowingConfirmationAlert = Binding<Bool>(get: {
            viewModel.urls.first != nil && selectedNotMatchedItem != nil
        }, set: { newValue in
            if !newValue {
                selectedNotMatchedItem = nil
            }
        })

        ZStack {
            Color.passBackground
                .ignoresSafeArea()

            if isLocked {
                AppLockedView(preferences: preferences,
                              logManager: viewModel.logManager,
                              delayed: true,
                              onSuccess: { isLocked = false },
                              onFailure: viewModel.handleAuthenticationFailure)
            } else {
                switch viewModel.state {
                case .loading:
                    CredentialsSkeletonView()

                case let .loaded(result, state):
                    if result.isEmpty {
                        NoCredentialsView()
                    } else {
                        VStack(spacing: 0) {
                            SearchBar(query: $query,
                                      placeholder: "Search in all vaults",
                                      onCancel: viewModel.cancel)

                            switch state {
                            case .idle:
                                itemList(matchedItems: result.matchedItems,
                                         notMatchedItems: result.notMatchedItems)

                            case .searching:
                                ProgressView()

                            case .noSearchResults:
                                Text("No search results")
                                    .foregroundColor(.textWeak)

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
        .ignoresSafeArea(edges: .bottom)
        .theme(preferences.theme)
        .tint(.passBrand)
        .alert(
            "Associate URL?",
            isPresented: isShowingConfirmationAlert,
            actions: {
                if let selectedNotMatchedItem {
                    Button(action: {
                        viewModel.associateAndAutofill(item: selectedNotMatchedItem)
                    }, label: {
                        Text("Associate and autofill")
                    })

                    Button(action: {
                        viewModel.select(item: selectedNotMatchedItem)
                    }, label: {
                        Text("Just autofill")
                    })
                }

                Button(role: .cancel) {
                    Text("Cancel")
                }
            },
            message: {
                if let selectedNotMatchedItem,
                   let schemeAndHost = viewModel.urls.first?.schemeAndHost {
                    // swiftlint:disable:next line_length
                    Text("Would you want to associate \"\(schemeAndHost)\" with \"\(selectedNotMatchedItem.itemTitle)\"?")
                }
            })
    }

    private func itemList(matchedItems: [ItemUiModel],
                          notMatchedItems: [ItemUiModel]) -> some View {
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
                }
            }, header: {
                if let host = viewModel.urls.first?.host {
                    header(text: "Suggestions for \(host)")
                }
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
                }
            }, header: {
                header(text: "Others items")
            })
        }
        .listStyle(.plain)
        .refreshable { await viewModel.forceSync() }
        .animation(.default, value: matchedItems.hashValue)
        .animation(.default, value: notMatchedItems.hashValue)
    }

    private func view(for item: ItemUiModel) -> some View {
        Button(action: {
            viewModel.select(item: item)
        }, label: {
            GeneralItemRow(thumbnailView: { EmptyView() },
                           title: item.title,
                           description: item.description)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
        })
        .listRowSeparator(.hidden)
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
    }

    private func header(text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(.secondary)
            .font(.callout)
    }

    private func searchResultsList(_ results: [ItemSearchResult]) -> some View {
        List {
            ForEach(results, id: \.hashValue) { result in
                Button(action: {
                    select(item: result)
                }, label: {
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
                })
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .animation(.default, value: results.count)
    }

    private func select(item: TitledItemIdentifiable) {
        guard case .loaded(let credentialsFetchResult, _) = viewModel.state else { return }
        let isMatched = credentialsFetchResult.matchedItems
            .contains { $0.itemId == item.itemId && $0.shareId == item.shareId }
        if isMatched {
            viewModel.select(item: item)
        } else {
            // Check URL validity (e.g app has associated domains or not)
            // before asking if user wants to "associate & autofill".
            if let schemeAndHost = viewModel.urls.first?.schemeAndHost,
               !schemeAndHost.isEmpty {
                selectedNotMatchedItem = item
            } else {
                viewModel.select(item: item)
            }
        }
    }
}

private struct CredentialsSkeletonView: View {
    var body: some View {
        VStack {
            HStack {
                AnimatingGradient()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                AnimatingGradient()
                    .frame(width: kSearchBarHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(height: kSearchBarHeight)
            .padding(.vertical)

            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(0..<20, id: \.self) { _ in
                        itemRow
                    }
                }
            }
            .disabled(true)
        }
        .padding(.horizontal)
    }

    private var itemRow: some View {
        HStack(spacing: 16) {
            AnimatingGradient()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Spacer()
                AnimatingGradient()
                    .frame(width: 170, height: 10)
                    .clipShape(Capsule())
                Spacer()
                AnimatingGradient()
                    .frame(width: 200, height: 10)
                    .clipShape(Capsule())
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
