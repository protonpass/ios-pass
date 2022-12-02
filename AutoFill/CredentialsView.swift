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
                    Group {
                        switch viewModel.state {
                        case .loading:
                            ProgressView()
                        case .loaded:
                            if viewModel.matchedItems.isEmpty, viewModel.notMatchedItems.isEmpty {
                                NoCredentialsView()
                            } else {
                                VStack(spacing: 0) {
                                    SwiftUISearchBar(placeholder: "Search...",
                                                     showsCancelButton: false,
                                                     shouldBecomeFirstResponder: false,
                                                     onSearch: { _ in },
                                                     onCancel: {})
                                    itemList
                                }
                            }
                        case .error(let error):
                            RetryableErrorView(errorMessage: error.messageForTheUser,
                                               onRetry: viewModel.fetchItems)
                        }
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
    }

    private var itemList: some View {
        List {
            if !viewModel.matchedItems.isEmpty {
                Section(content: {
                    ForEach(viewModel.matchedItems, id: \.itemId) { item in
                        view(for: item)
                    }
                    .listRowSeparator(.hidden)
                }, header: {
                    Text("Suggestions for \(viewModel.matchedHost)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.secondary)
                        .font(.callout)
                })
            }

            if !viewModel.notMatchedItems.isEmpty {
                Section(content: {
                    ForEach(viewModel.notMatchedItems, id: \.itemId) { item in
                        view(for: item)
                    }
                    .listRowSeparator(.hidden)
                }, header: {
                    Text("Others items")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.secondary)
                        .font(.callout)
                })
            }
        }
        .listStyle(.plain)
        .animation(.default, value: viewModel.matchedItems.count + viewModel.notMatchedItems.count)
    }

    private func view(for item: ItemListUiModel) -> some View {
        GenericItemView(
            item: item,
            action: { viewModel.select(item: item) },
            trailingView: { EmptyView() })
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
    }
}
