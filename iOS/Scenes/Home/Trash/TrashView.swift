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
        Group {
            if !viewModel.trashedItem.isEmpty {
                itemList
            } else if viewModel.isFetchingItems {
                ProgressView()
            } else if viewModel.trashedItem.isEmpty {
                EmptyTrashView()
            }
        }
        .toolbar { toolbarContent }
        .alert(isPresented: $isShowingEmptyTrashAlert) { emptyTrashAlert }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ToggleSidebarButton(action: viewModel.toggleSidebar)
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
            .opacity(viewModel.trashedItem.isEmpty ? 0 : 1)
            .disabled(viewModel.trashedItem.isEmpty)
        }
    }

    private var emptyTrashAlert: Alert {
        Alert(title: Text("Empty trash?"),
              message: Text("Items in trash will be deleted permanently. You can not undo this action"),
              primaryButton: .destructive(Text("Empty trash"), action: viewModel.emptyTrash),
              secondaryButton: .default(Text("Cancel")))
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.trashedItem, id: \.itemId) { item in
                    GenericItemView(
                        item: item,
                        showDivider: item.itemId != viewModel.trashedItem.last?.itemId,
                        action: {  },
                        trailingView: {
                            VStack {
                                Menu(content: {
                                    DestructiveButton(
                                        title: "Move to Trash",
                                        icon: IconProvider.trash,
                                        action: {})
                                }, label: {
                                    Image(uiImage: IconProvider.threeDotsHorizontal)
                                        .foregroundColor(.secondary)
                                })
                                .padding(.top, 16)

                                Spacer()
                            }
                        })
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
        }
    }
}
