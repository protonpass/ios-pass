//
// OneTimeCodesView.swift
// Proton Pass - Created on 18/09/2024.
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
import Screens
import SwiftUI

struct OneTimeCodesView: View {
    @StateObject private var viewModel: OneTimeCodesViewModel
    @FocusState private var isFocusedOnSearchBar

    init(viewModel: OneTimeCodesViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            stateView
        }
        .task {
            await viewModel.fetchItems()
            await viewModel.sync(ignoreError: true)
        }
        .localAuthentication(onSuccess: { _ in viewModel.handleAuthenticationSuccess() },
                             onFailure: { _ in viewModel.handleAuthenticationFailure() })
        .task {
            await viewModel.fetchItems()
            await viewModel.sync(ignoreError: true)
        }
    }
}

private extension OneTimeCodesView {
    var stateView: some View {
        VStack(spacing: 0) {
            SearchBar(query: $viewModel.query,
                      isFocused: $isFocusedOnSearchBar,
                      placeholder: viewModel.searchBarPlaceholder,
                      onCancel: { viewModel.handleCancel() })

            switch viewModel.state {
            case .loading:
                ProgressView()

            case .loaded:
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
                    if viewModel.matchedItems.isEmpty,
                       viewModel.notMatchedItems.isEmpty {
                        VStack {
                            Spacer()
                            Text("You currently have no login items")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .padding()
                            Spacer()
                        }
                    } else {
                        itemList(matchedItems: viewModel.matchedItems,
                                 notMatchedItems: viewModel.notMatchedItems)
                    }
                }

            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: { Task { await viewModel.fetchItems() } })
            }
        }
    }
}

private extension OneTimeCodesView {
    func itemList(matchedItems: [ItemUiModel],
                  notMatchedItems: [ItemUiModel]) -> some View {
        ScrollViewReader { _ in
            List {
                if !viewModel.urls.isEmpty {
                    section(for: matchedItems,
                            title: "Suggestions for \(viewModel.domain)",
                            emptyMessage: "No suggestions")
                }

                section(for: notMatchedItems,
                        title: "Other items",
                        emptyMessage: "No suggestions")
            }
            .listStyle(.plain)
            .refreshable { await viewModel.sync(ignoreError: false) }
            .animation(.default, value: matchedItems.hashValue)
            .animation(.default, value: notMatchedItems.hashValue)
        }
    }

    func section(for items: [ItemUiModel],
                 title: LocalizedStringKey,
                 emptyMessage: LocalizedStringKey) -> some View {
        Section(content: {
            if items.isEmpty {
                Text(emptyMessage)
                    .font(.callout.italic())
                    .padding(.horizontal)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .plainListRow()
            } else {
                ForEach(items) { item in
                    AuthenticatorRow(thumbnailView: {
                                         EmptyView()
                                     },
                                     uri: item.totpUri ?? "",
                                     title: item.title,
                                     totpManager: SharedServiceContainer.shared.totpManager(),
                                     onCopyTotpToken: { _ in viewModel.select(item: item) })
                        .plainListRow()
                }
            }
        }, header: {
            Text(title)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
        })
    }
}
