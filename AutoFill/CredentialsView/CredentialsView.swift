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
import DesignSystem
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CredentialsView: View {
    @StateObject private var viewModel: CredentialsViewModel
    @FocusState private var isFocusedOnSearchBar
    private let preferences = resolve(\SharedToolingContainer.preferences)

    init(viewModel: CredentialsViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color(uiColor: PassColor.backgroundNorm)
                .ignoresSafeArea()
            stateViews
        }
//        .task {
//            await viewModel.sync()
//        }
        .theme(preferences.theme)
        .localAuthentication(delayed: false,
                             onAuth: {},
                             onSuccess: viewModel.handleAuthenticationSuccess,
                             onFailure: viewModel.handleAuthenticationFailure)
        .alert("Associate URL?",
               isPresented: $viewModel.isShowingConfirmationAlert,
               actions: {
                   if let information = viewModel.notMatchedItemInformation {
                       Button(action: {
                           viewModel.associateAndAutofill(item: information.item)
                       }, label: {
                           Text("Associate and autofill")
                       })

                       Button(action: {
                           viewModel.select(item: information.item)
                       }, label: {
                           Text("Just autofill")
                       })
                   }

                   Button(role: .cancel) {
                       Text("Cancel")
                   }
               },
               message: {
                   if let information = viewModel.notMatchedItemInformation {
                       // swiftlint:disable:next line_length
                       Text("Would you want to associate « \(information.url) » with « \(information.item.itemTitle) »?")
                   }
               })
    }
}

private extension CredentialsView {
    @ViewBuilder
    var stateViews: some View {
        VStack(spacing: 0) {
            if viewModel.state != .loading {
                SearchBar(query: $viewModel.query,
                          isFocused: $isFocusedOnSearchBar,
                          placeholder: viewModel.planType?.searchBarPlaceholder ?? "",
                          onCancel: viewModel.cancel)
            }
            switch viewModel.state {
            case .idle:
                if let planType = viewModel.planType, case .free = planType {
                    mainVaultsOnlyMessage
                }
                if let results = viewModel.results {
                    if results.isEmpty {
                        VStack {
                            Spacer()
                            Text("You currently have no login items")
                                .multilineTextAlignment(.center)
                                .foregroundColor(PassColor.textNorm.toColor)
                                .padding()
                            Spacer()
                        }
                    } else {
                        itemList(results: results)
                    }
                }
            case .searching:
                ProgressView()
            case let .searchResults(results):
                if results.isEmpty {
                    NoSearchResultsInAllVaultView(query: viewModel.query)
                } else {
                    CredentialSearchResultView(results: results,
                                               selectedSortType: $viewModel.selectedSortType,
                                               sortAction: viewModel.presentSortTypeList,
                                               selectItem: viewModel.select)
                }
            case .loading:
                CredentialsSkeletonView()
            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: viewModel.fetchItems)
            }

            Spacer()

            CapsuleTextButton(title: #localized("Create login"),
                              titleColor: PassColor.loginInteractionNormMajor2,
                              backgroundColor: PassColor.loginInteractionNormMinor1,
                              height: 52,
                              action: viewModel.createLoginItem)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.planType)
    }
}

// MARK: ResultView & elements

private extension CredentialsView {
    func itemList(results: CredentialsFetchResult) -> some View {
        ScrollViewReader { proxy in
            List {
                let matchedItemsHeaderTitle = #localized("Suggestions for %@", viewModel.urls.first?.host ?? "")
                if results.matchedItems.isEmpty {
                    Section(content: {
                        Text("No suggestions")
                            .font(.callout.italic())
                            .padding(.horizontal)
                            .foregroundColor(PassColor.textWeak.toColor)
                            .plainListRow()
                    }, header: {
                        Text(matchedItemsHeaderTitle)
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(PassColor.textNorm.toColor)
                    })
                } else {
                    section(for: results.matchedItems,
                            headerTitle: matchedItemsHeaderTitle,
                            headerColor: PassColor.textNorm,
                            headerFontWeight: .bold)
                }

                if !results.notMatchedItems.isEmpty {
                    HStack {
                        Text("Other items")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(PassColor.textNorm.toColor) +
                            Text(verbatim: " (\(results.notMatchedItems.count))")
                            .font(.callout)
                            .foregroundColor(PassColor.textWeak.toColor)

                        Spacer()

                        SortTypeButton(selectedSortType: $viewModel.selectedSortType,
                                       action: viewModel.presentSortTypeList)
                    }
                    .plainListRow()
                    .padding([.top, .horizontal])
                    sortableSections(for: results.notMatchedItems)
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.sync() }
            .animation(.default, value: results.matchedItems.hashValue)
            .animation(.default, value: results.notMatchedItems.hashValue)
            .overlay {
                if viewModel.selectedSortType.isAlphabetical {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy,
                                           direction: viewModel.selectedSortType.sortDirection ?? .ascending)
                    }
                }
            }
        }
    }

    var mainVaultsOnlyMessage: some View {
        ZStack {
            Text("Your plan only allows to use items from your first vaults for autofill purposes.")
                .foregroundColor(PassColor.textNorm.toColor) +
                Text(verbatim: " ") +
                Text("Upgrade now")
                .underline(color: PassColor.interactionNormMajor1.toColor)
                .foregroundColor(PassColor.interactionNormMajor1.toColor)
        }
        .padding()
        .background(PassColor.interactionNormMinor1.toColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: viewModel.upgrade)
    }
}

// MARK: Sections & elements

private extension CredentialsView {
    @ViewBuilder
    func section(for items: [some CredentialItem],
                 headerTitle: String,
                 headerColor: UIColor = PassColor.textWeak,
                 headerFontWeight: Font.Weight = .regular) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    GenericCredentialItemRow(item: item, selectItem: viewModel.select)
                        .plainListRow()
                        .padding(.horizontal)
                }
            }, header: {
                Text(headerTitle)
                    .font(.callout)
                    .fontWeight(headerFontWeight)
                    .foregroundColor(headerColor.toColor)
            })
        }
    }

    @ViewBuilder
    func sortableSections(for items: [some CredentialItem]) -> some View {
        switch viewModel.selectedSortType {
        case .mostRecent:
            sections(for: items.mostRecentSortResult())
        case .alphabeticalAsc:
            sections(for: items.alphabeticalSortResult(direction: .ascending))
        case .alphabeticalDesc:
            sections(for: items.alphabeticalSortResult(direction: .descending))
        case .newestToOldest:
            sections(for: items.monthYearSortResult(direction: .descending))
        case .oldestToNewest:
            sections(for: items.monthYearSortResult(direction: .ascending))
        }
    }

    func sections(for result: MostRecentSortResult<some CredentialItem>) -> some View {
        Group {
            section(for: result.today, headerTitle: #localized("Today"))
            section(for: result.yesterday, headerTitle: #localized("Yesterday"))
            section(for: result.last7Days, headerTitle: #localized("Last week"))
            section(for: result.last14Days, headerTitle: #localized("Last two weeks"))
            section(for: result.last30Days, headerTitle: #localized("Last 30 days"))
            section(for: result.last60Days, headerTitle: #localized("Last 60 days"))
            section(for: result.last90Days, headerTitle: #localized("Last 90 days"))
            section(for: result.others, headerTitle: #localized("More than 90 days"))
        }
    }

    func sections(for result: AlphabeticalSortResult<some CredentialItem>) -> some View {
        ForEach(result.buckets, id: \.letter) { bucket in
            section(for: bucket.items, headerTitle: bucket.letter.character)
                .id(bucket.letter.character)
        }
    }

    func sections(for result: MonthYearSortResult<some CredentialItem>) -> some View {
        ForEach(result.buckets, id: \.monthYear) { bucket in
            section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
        }
    }
}

// MARK: SkeletonView

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
