//
// VaultContentView.swift
// Proton Pass - Created on 21/07/2022.
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

struct VaultContentView: View {
    @StateObject private var viewModel: VaultContentViewModel
    @State private var selectedItem: ItemListUiModel?
    @State private var isShowingTrashingAlert = false

    private var selectedVaultName: String {
        viewModel.selectedVault?.name ?? "All vaults"
    }

    init(viewModel: VaultContentViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingVaultView()
                    .padding()

            case .loaded:
                if viewModel.filteredItems.isEmpty {
                    EmptyVaultView()
                        .padding(.horizontal)
                } else {
                    itemList
                        .opacityReduced(viewModel.isLoading)

                    if viewModel.isLoading {
                        ProgressView()
                    }
                }

            case .error(let error):
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: { viewModel.fetchItems(forceRefresh: true) })
                .padding()
            }
        }
        .moveToTrashAlert(isPresented: $isShowingTrashingAlert) {
            if let selectedItem {
                viewModel.trashItem(selectedItem)
            }
        }
        .toolbar { toolbarContent }
        .onAppear { viewModel.fetchItems(forceRefresh: false) }
    }

    private var filterStatus: some View {
        Menu(content: {
            ForEach(viewModel.sortTypes, id: \.self) { sortType in
                Button(action: {
                    viewModel.sortType = sortType
                }, label: {
                    Label(title: {
                        Text(sortType.description)
                    }, icon: {
                        if sortType == viewModel.sortType {
                            Image(systemName: "checkmark")
                        }
                    })
                })
            }
            Divider()
            ForEach(SortDirection.allCases, id: \.self) { sortDirection in
                Button(action: {
                    viewModel.sortDirection = sortDirection
                }, label: {
                    Label(title: {
                        Text(sortDirection.description)
                    }, icon: {
                        if sortDirection == viewModel.sortDirection {
                            Image(systemName: "checkmark")
                        }
                    })
                })
            }
        }, label: {
            HStack {
                Text("Sort by: \(viewModel.sortType.description)")
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .font(.callout)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var itemList: some View {
        List {
            Section(content: {
                ForEach(viewModel.filteredItems, id: \.itemId) { item in
                    GenericItemView(item: item,
                                    action: { viewModel.selectItem(item) },
                                    subtitleLineLimit: 1,
                                    trailingView: { trailingView(for: item) })
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                }
                .listRowSeparator(.hidden)
            }, header: {
                filterStatus
            })
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .animation(.default, value: viewModel.filteredItems.count)
        .refreshable { await viewModel.forceRefreshItems() }
    }

    private func trailingView(for item: ItemListUiModel) -> some View {
        VStack {
            Spacer()

            Menu(content: {
                switch item.type {
                case .login:
                    CopyMenuButton(title: "Copy username",
                                   action: { viewModel.copyUsername(item) })

                    CopyMenuButton(title: "Copy password",
                                   action: { viewModel.copyPassword(item) })

                case .alias:
                    CopyMenuButton(title: "Copy email address",
                                   action: { viewModel.copyEmailAddress(item) })
                case .note:
                    if case .value = item.detail {
                        CopyMenuButton(title: "Copy note",
                                       action: { viewModel.copyNote(item) })
                    }
                }

                EditMenuButton {
                    viewModel.editItem(item)
                }

                Divider()

                DestructiveButton(
                    title: "Move to Trash",
                    icon: IconProvider.trash,
                    action: {
                        selectedItem = item
                        isShowingTrashingAlert.toggle()
                    })
            }, label: {
                Image(uiImage: IconProvider.threeDotsHorizontal)
                    .foregroundColor(.secondary)
            })

            Spacer()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ToggleSidebarButton(action: viewModel.toggleSidebar)
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.filterOption.title)
                .fontWeight(.semibold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Button(action: viewModel.search) {
                    Image(uiImage: IconProvider.magnifier)
                }

                Button(action: viewModel.createItem) {
                    Image(uiImage: IconProvider.plus)
                }
            }
            .foregroundColor(Color(.label))
            .opacityReduced(!viewModel.state.isLoaded, reducedOpacity: 0)
        }
    }
}
