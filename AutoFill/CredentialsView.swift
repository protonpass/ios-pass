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
import Combine
import Core
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CredentialsView: View {
    @StateObject private var viewModel: CredentialsViewModel
    @FocusState private var isFocusedOnSearchBar
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
            Color(uiColor: PassColor.backgroundNorm)
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
                        NoCredentialsView(onCancel: viewModel.cancel,
                                          onCreate: viewModel.createLoginItem)
                    } else {
                        resultView(result: result, state: state)
                    }

                case .error(let error):
                    RetryableErrorView(errorMessage: error.localizedDescription,
                                       onRetry: viewModel.fetchItems)
                }
            }
        }
        .theme(preferences.theme)
        .animation(.default, value: isLocked)
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

    private func resultView(result: CredentialsFetchResult,
                            state: CredentialsViewLoadedState) -> some View {
        VStack(spacing: 0) {
            SearchBar(query: $query,
                      isFocused: $isFocusedOnSearchBar,
                      placeholder: "Search in all vaults",
                      onCancel: viewModel.cancel)

            switch state {
            case .idle:
                itemList(matchedItems: result.matchedItems,
                         notMatchedItems: result.notMatchedItems)

            case .searching:
                ProgressView()

            case .noSearchResults:
                NoSearchResultsInAllVaultView(query: query)

            case .searchResults(let results):
                searchResults(results)
            }

            Spacer()

            CreateLoginButton(onCreate: viewModel.createLoginItem)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: state)
        .onChange(of: query) { viewModel.search(term: $0) }
    }

    // swiftlint:disable:next function_body_length
    private func itemList(matchedItems: [ItemUiModel],
                          notMatchedItems: [ItemUiModel]) -> some View {
        ScrollViewReader { proxy in
            List {
                let matchedItemsHeaderTitle = "Suggestions for \(viewModel.urls.first?.host ?? "")"
                if matchedItems.isEmpty {
                    Section(content: {
                        Text("No suggestions")
                            .font(.callout.italic())
                            .padding(.horizontal)
                            .foregroundColor(Color(uiColor: PassColor.textWeak))
                            .plainListRow()
                    }, header: {
                        Text(matchedItemsHeaderTitle)
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(Color(uiColor: PassColor.textNorm))
                    })
                } else {
                    section(for: matchedItems.map { .normal($0) },
                            headerTitle: matchedItemsHeaderTitle,
                            headerColor: PassColor.textNorm,
                            headerFontWeight: .bold)
                }

                if !notMatchedItems.isEmpty {
                    HStack {
                        Text("Other items")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(Color(uiColor: PassColor.textNorm)) +
                        Text(" (\(notMatchedItems.count))")
                            .font(.callout)
                            .foregroundColor(Color(uiColor: PassColor.textWeak))

                        Spacer()

                        SortTypeButton(selectedSortType: $viewModel.selectedSortType,
                                       action: viewModel.presentSortTypeList)
                    }
                    .plainListRow()
                    .padding([.top, .horizontal])

                    sortableSections(for: notMatchedItems.map { .normal($0) })
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.forceSync() }
            .animation(.default, value: matchedItems.hashValue)
            .animation(.default, value: notMatchedItems.hashValue)
            .overlay {
                if viewModel.selectedSortType == .alphabetical {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy)
                    }
                }
            }
        }
    }

    private func searchResults(_ results: [ItemSearchResult]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Results")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(Color(uiColor: PassColor.textNorm)) +
                Text(" (\(results.count))")
                    .font(.callout)
                    .foregroundColor(Color(uiColor: PassColor.textWeak))

                Spacer()

                SortTypeButton(selectedSortType: $viewModel.selectedSortType,
                               action: viewModel.presentSortTypeList)
            }
            .padding([.bottom, .horizontal])

            ScrollViewReader { proxy in
                List {
                    sortableSections(for: results.map { .searchResult($0) })
                }
                .listStyle(.plain)
                .animation(.default, value: results.count)
                .overlay {
                    if viewModel.selectedSortType == .alphabetical {
                        HStack {
                            Spacer()
                            SectionIndexTitles(proxy: proxy)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func section(for items: [CredentialItem],
                         headerTitle: String,
                         headerColor: UIColor = PassColor.textWeak,
                         headerFontWeight: Font.Weight = .regular) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    switch item {
                    case .normal(let normalItem):
                        itemRow(for: normalItem)
                            .plainListRow()
                            .padding(.horizontal)
                    case .searchResult(let searchResultItem):
                        itemRow(for: searchResultItem)
                            .plainListRow()
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                }
            }, header: {
                Text(headerTitle)
                    .font(.callout)
                    .fontWeight(headerFontWeight)
                    .foregroundColor(Color(uiColor: headerColor))
            })
        }
    }

    @ViewBuilder
    private func sortableSections(for items: [CredentialItem]) -> some View {
        switch viewModel.selectedSortType {
        case .mostRecent:
            sections(for: items.mostRecentSortResult())
        case .alphabetical:
            sections(for: items.alphabeticalSortResult())
        case .newestToOldest:
            sections(for: items.monthYearSortResult(direction: .descending))
        case .oldestToNewest:
            sections(for: items.monthYearSortResult(direction: .ascending))
        }
    }

    private func sections(for result: MostRecentSortResult<CredentialItem>) -> some View {
        Group {
            section(for: result.today, headerTitle: "Today")
            section(for: result.yesterday, headerTitle: "Yesterday")
            section(for: result.last7Days, headerTitle: "Last week")
            section(for: result.last14Days, headerTitle: "Last two weeks")
            section(for: result.last30Days, headerTitle: "Last 30 days")
            section(for: result.last60Days, headerTitle: "Last 60 days")
            section(for: result.last90Days, headerTitle: "Last 90 days")
            section(for: result.others, headerTitle: "More than 90 days")
        }
    }

    private func sections(for result: AlphabeticalSortResult<CredentialItem>) -> some View {
        ForEach(result.buckets, id: \.letter) { bucket in
            section(for: bucket.items, headerTitle: bucket.letter.character)
                .id(bucket.letter.character)
        }
    }

    private func sections(for result: MonthYearSortResult<CredentialItem>) -> some View {
        ForEach(result.buckets, id: \.monthYear) { bucket in
            section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
        }
    }

    private func itemRow(for item: ItemUiModel) -> some View {
        Button(action: {
            select(item: item)
        }, label: {
            GeneralItemRow(
                thumbnailView: {
                    ItemSquircleThumbnail(data: item.thumbnailData(),
                                          repository: viewModel.favIconRepository)
                },
                title: item.title,
                description: item.description)
            .frame(maxWidth: .infinity, alignment: .leading)
        })
    }

    private func itemRow(for item: ItemSearchResult) -> some View {
        Button(action: {
            select(item: item)
        }, label: {
            HStack {
                VStack {
                    ItemSquircleThumbnail(data: item.thumbnailData(),
                                          repository: viewModel.favIconRepository)
                }
                .frame(maxHeight: .infinity, alignment: .top)

                VStack(alignment: .leading, spacing: 4) {
                    HighlightText(highlightableText: item.highlightableTitle)

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<item.highlightableDetail.count, id: \.self) { index in
                            let eachDetail = item.highlightableDetail[index]
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
        })
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
