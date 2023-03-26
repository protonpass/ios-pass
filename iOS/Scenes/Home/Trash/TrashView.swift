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
    @State private var itemToBeDeleted: ItemUiModel?
    @State private var isShowingEmptyTrashAlert = false

    init(viewModel: TrashViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        let isShowingDeleteConfirmation = Binding<Bool>(get: {
            itemToBeDeleted != nil
        }, set: { newValue in
            if !newValue {
                itemToBeDeleted = nil
            }
        })

        Group {
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
                                   onRetry: { Task { await viewModel.forceSync() } })
            }
        }
        .navigationTitle("Trash")
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
        .alert(
            "Permanently delete",
            isPresented: isShowingDeleteConfirmation,
            actions: {
                if let itemToBeDeleted {
                    Button(role: .destructive,
                           action: { viewModel.deletePermanently(itemToBeDeleted) },
                           label: { Text("Delete item") })
                }
            },
            message: {
                // swiftlint:disable:next line_length
                Text("\"\(itemToBeDeleted?.title ?? "")\" will be deleted permanently.\nYou can not undo this action.")
            })
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ToggleSidebarButton(action: viewModel.toggleSidebar)
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
            .opacityReduced(viewModel.isEmpty, reducedOpacity: 0)
        }
    }

    private var itemList: some View {
        List {
            ForEach(Array(viewModel.itemsDictionary.keys).sorted(), id: \.self) { vaultName in
                if let items = viewModel.itemsDictionary[vaultName] {
                    Section(content: {
                        ForEach(items, id: \.itemId) { item in
                            Button(action: {
                                viewModel.selectItem(item)
                            }, label: {
                                GeneralItemRow(thumbnailView: { EmptyView() },
                                               title: item.title,
                                               description: item.description)
                            })
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                            .swipeActions {
                                Button(action: { viewModel.restore(item) },
                                       label: { Image(uiImage: IconProvider.clockRotateLeft) })
                                .tint(.blue)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }, header: {
                        Text(vaultName)
                    })
                }
            }
        }
        .listStyle(.plain)
        .animation(.default, value: viewModel.items.count)
        .refreshable { await viewModel.forceSync() }
    }

    private func trailingView(for item: ItemUiModel) -> some View {
        Menu(content: {
            Button(action: {
                viewModel.restore(item)
            }, label: {
                Label(title: {
                    Text("Restore")
                }, icon: {
                    Image(uiImage: IconProvider.clockRotateLeft)
                })
            })

            Divider()

            DestructiveButton(
                title: "Permanently delete",
                icon: IconProvider.trash,
                action: { itemToBeDeleted = item })
        }, label: {
            Image(uiImage: IconProvider.threeDotsHorizontal)
                .foregroundColor(.secondary)
        })
    }
}
