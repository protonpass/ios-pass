//
// TrashedItemOptionsView.swift
// Proton Pass - Created on 12/09/2022.
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
import ProtonCore_UIFoundations
import SwiftUI

protocol TrashedItemOptionsViewDelegate: AnyObject {
    func trashedItemWantsToBeRestored(_ item: ItemListUiModel)
    func trashedItemWantsToShowDetail(_ item: ItemListUiModel)
    func trashedItemWantsToBeDeletedPermanently(_ item: ItemListUiModel)
}

struct TrashedItemOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteAlert = false
    let item: ItemListUiModel
    let delegate: TrashedItemOptionsViewDelegate

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    Button(action: {
                        delegate.trashedItemWantsToBeRestored(item)
                    }, label: {
                        Label(title: {
                            Text("Restore")
                        }, icon: {
                            Image(uiImage: IconProvider.clockRotateLeft)
                        })
                        .frame(maxWidth: .infinity, alignment: .leading)
                    })
                    .foregroundColor(.primary)

                    Divider()

                    Button(action: {
                        delegate.trashedItemWantsToShowDetail(item)
                    }, label: {
                        Label(title: {
                            Text("Details")
                        }, icon: {
                            Image(uiImage: IconProvider.infoCircle)
                        })
                        .frame(maxWidth: .infinity, alignment: .leading)
                    })
                    .foregroundColor(.primary)

                    Divider()

                    Button(
                        role: .destructive,
                        action: {
                            isShowingDeleteAlert.toggle()
                        },
                        label: {
                            Label(title: {
                                Text("Delete permanently")
                            }, icon: {
                                Image(uiImage: IconProvider.trash)
                            })
                            .frame(maxWidth: .infinity, alignment: .leading)
                        })

                    Spacer()
                }
                .padding(.horizontal)
            }
            .toolbar { toolbarContent }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(
            "Delete permanently",
            isPresented: $isShowingDeleteAlert,
            actions: {
                Button(
                    "Delete item",
                    role: .destructive,
                    action: {
                        delegate.trashedItemWantsToBeDeletedPermanently(item)
                    })
            }, message: {
                Text("Item will be deleted permanently. You can not undo this action.")
            })
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: dismiss.callAsFunction) {
                Image(uiImage: IconProvider.cross)
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .principal) {
            Text(item.title)
                .fontWeight(.bold)
        }
    }
}
