//
// ItemsForTextInsertionView.swift
// Proton Pass - Created on 27/09/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct ItemsForTextInsertionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ItemsForTextInsertionViewModel
    @FocusState private var isFocusedOnSearchBar

    init(viewModel: ItemsForTextInsertionViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            stateViews
        }
        .task {
            await viewModel.fetchItems()
            await viewModel.sync(ignoreError: true)
        }
        .localAuthentication(onSuccess: { _ in viewModel.handleAuthenticationSuccess() },
                             onFailure: { _ in viewModel.handleAuthenticationFailure() })
        .optionalSheet(binding: $viewModel.selectedItem) { selectedItem in
            ItemDetailView(userId: selectedItem.userId,
                           itemContent: selectedItem.item,
                           vault: selectedItem.vault,
                           onSelect: { viewModel.autofill($0) })
                .environment(\.colorScheme, colorScheme)
        }
    }
}

private extension ItemsForTextInsertionView {
    var stateViews: some View {
        VStack(spacing: 0) {
            if viewModel.state != .loading {
                HStack(spacing: 0) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Close",
                                 action: { viewModel.handleCancel() })
                    SearchBar(query: $viewModel.query,
                              isFocused: $isFocusedOnSearchBar,
                              placeholder: viewModel.searchBarPlaceholder,
                              onCancel: { /* Not applicable */ },
                              hideCancel: true)
                }
                .padding(.horizontal)
            }
            switch viewModel.state {
            case .idle:
                if viewModel.users.count > 1 {
                    UserAccountSelectionMenu(selectedUser: $viewModel.selectedUser,
                                             users: viewModel.users)
                        .padding(.horizontal)
                }

                if viewModel.isFreeUser {
                    MainVaultsOnlyBanner(onTap: { viewModel.upgrade() })
                        .padding([.horizontal, .top])
                }

                if !viewModel.results.isEmpty {
                    if viewModel.items.isEmpty {
                        VStack {
                            Spacer()
                            Text(verbatim: "Empty")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .padding()
                            Spacer()
                        }
                    } else {
                        itemList
                    }
                }
            case .searching:
                ProgressView()
            case let .searchResults(results):
                EmptyView()
            case .loading:
                CredentialsSkeletonView()
            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: { Task { await viewModel.fetchItems() } })
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.selectedUser)
        .animation(.default, value: viewModel.results)
    }
}

private extension ItemsForTextInsertionView {
    @ViewBuilder
    var itemList: some View {
        let sections: [TableView<ItemUiModel, GenericCredentialItemRow>.Section] = {
            switch viewModel.selectedSortType {
            case .mostRecent:
                let results = viewModel.items.mostRecentSortResult()
                return [
                    .init(title: #localized("Today"), items: results.today),
                    .init(title: #localized("Yesterday"), items: results.yesterday),
                    .init(title: #localized("Last week"), items: results.last7Days),
                    .init(title: #localized("Last two weeks"), items: results.last14Days),
                    .init(title: #localized("Last 30 days"), items: results.last30Days),
                    .init(title: #localized("Last 60 days"), items: results.last60Days),
                    .init(title: #localized("Last 90 days"), items: results.last90Days),
                    .init(title: #localized("More than 90 days"), items: results.others)
                ]
            default:
                return []
            }
        }()
        TableView(sections: sections,
                  showIndexTitles: viewModel.selectedSortType.isAlphabetical) { item in
            GenericCredentialItemRow(item: item,
                                     user: nil,
                                     selectItem: { viewModel.select($0) })
        }
        .padding(.top)
    }
}
