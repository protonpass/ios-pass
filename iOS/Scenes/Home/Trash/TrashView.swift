//
// TrashView.swift
// Proton Pass - Created on 07/07/2022.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct TrashView: View {
    @StateObject private var viewModel: TrashViewModel
    @State private var isShowingEmptyTrashAlert = false

    init(viewModel: TrashViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.clear
            switch viewModel.state {
            case .loading:
                ProgressView()

            case .loaded:
                if viewModel.items.isEmpty {
                    EmptyTrashView()
                } else {
                    itemList
                }

            case .error(let error):
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: { viewModel.fetchAllTrashedItems(forceRefresh: true) })
            }
        }
        .toolbar { toolbarContent }
        .alert(
            "Empty trash?",
            isPresented: $isShowingEmptyTrashAlert,
            actions: {
                Button("Empty trash", role: .destructive, action: viewModel.emptyTrash)
            },
            message: {
                Text("Items in trash will be deleted permanently. You can not undo this action.")
            })
        .alertToastSuccessMessage($viewModel.successMessage)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ToggleSidebarButton { viewModel.onToggleSidebar?() }
        }

        ToolbarItem(placement: .principal) {
            Text("Trash")
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Menu(content: {
                Button(action: viewModel.restoreAllItems) {
                    Label(title: {
                        Text("Restore all items")
                    }, icon: {
                        Image(uiImage: IconProvider.clockRotateLeft)
                    })
                }

                DestructiveButton(title: "Empty trash",
                                  icon: IconProvider.trashCross) {
                    isShowingEmptyTrashAlert.toggle()
                }
            }, label: {
                Image(uiImage: IconProvider.threeDotsHorizontal)
                    .foregroundColor(Color(.label))
            })
            .opacity(viewModel.isEmpty ? 0 : 1)
            .disabled(viewModel.isEmpty)
        }
    }

    private var itemList: some View {
        List {
            ForEach(viewModel.items, id: \.itemId) { item in
                VStack(spacing: 8) {
                    GenericItemView(
                        item: item,
                        action: { viewModel.showOptions(item) },
                        trailingView: {
                            Button(action: {
                                viewModel.showOptions(item)
                            }, label: {
                                Image(uiImage: IconProvider.threeDotsHorizontal)
                                    .foregroundColor(.secondary)
                            })
                        })
                    if item.itemId != viewModel.items.last?.itemId {
                        Divider()
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .animation(.default, value: viewModel.items.count)
        .refreshable {
            await viewModel.forceRefreshItems()
        }
    }
}
