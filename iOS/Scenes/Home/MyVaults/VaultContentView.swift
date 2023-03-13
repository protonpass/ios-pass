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
    @State private var didAppear = false
    @State private var selectedItem: ItemListUiModelV2?
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
                ProgressView()

            case .loaded:
                if viewModel.filteredItems.isEmpty {
                    EmptyVaultView(onCreateNewItem: {})
                        .padding(.horizontal)
                } else {
                    itemList
                }

            case .error(let error):
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: { viewModel.fetchItems(showLoadingIndicator: true) })
                .padding()
            }
        }
        .moveToTrashAlert(isPresented: $isShowingTrashingAlert) {
            if let selectedItem {
                viewModel.trashItem(selectedItem)
            }
        }
        .toolbar { toolbarContent }
        .onAppear {
            if !didAppear {
                viewModel.fetchItems()
                didAppear = true
            }
        }
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
            if viewModel.shouldShowAutoFillBanner {
                TurnOnAutoFillBanner(onAction: viewModel.enableAutoFill,
                                     onCancel: viewModel.cancelAutoFillBanner)
                .shadow(radius: 16)
                .listRowSeparator(.hidden)
            }
            Section(content: {
                ForEach(viewModel.filteredItems, id: \.itemId) { item in
                    Button(action: {
                        viewModel.selectItem(item)
                    }, label: {
                        GeneralItemRow(thumbnailView: { EmptyView() },
                                       title: item.title,
                                       description: item.description)
                    })
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .swipeActions {
                        Button(action: { askForConfirmationOrTrashDirectly(item: item) },
                               label: { Image(uiImage: IconProvider.trash) })
                        .tint(.red)
                    }
                }
                .listRowSeparator(.hidden)
            }, header: {
                filterStatus
            })
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .animation(.default, value: viewModel.filteredItems.hashValue)
        .animation(.default, value: viewModel.shouldShowAutoFillBanner)
        .refreshable { await viewModel.forceSync() }
    }

    private func askForConfirmationOrTrashDirectly(item: ItemListUiModelV2) {
        if viewModel.preferences.askBeforeTrashing {
            selectedItem = item
            isShowingTrashingAlert.toggle()
        } else {
            viewModel.trashItem(item)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ToggleSidebarButton(action: viewModel.toggleSidebar)
        }

        ToolbarItem(placement: .principal) {
            VStack {
                Text(viewModel.filterOption.title)
                    .fontWeight(.semibold)
                if DeveloperModeStateManager.shared.isOn,
                   let selectedVault = viewModel.vaultSelection.selectedVault {
                    Text(selectedVault.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onTapGesture {
                if DeveloperModeStateManager.shared.isOn {
                    viewModel.showVaultList()
                }
            }
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
            .foregroundColor(.primary)
            .opacityReduced(!viewModel.state.isLoaded, reducedOpacity: 0)
        }
    }
}
