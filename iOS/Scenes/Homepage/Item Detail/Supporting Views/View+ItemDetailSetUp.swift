//
// View+ItemDetailSetUp.swift
// Proton Pass - Created on 08/08/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Screens
import SwiftUI

/// Set up common UI appearance for item detail pages
/// e.g. navigation bar, background color, toolbar, delete item alert...
struct ItemDetailSetUpModifier: ViewModifier {
    @ObservedObject var viewModel: BaseItemDetailViewModel
    @Environment(\.dismiss) private var dismiss

    private var tintColor: UIColor {
        viewModel.itemContent.type.normMajor2Color
    }

    func body(content: Content) -> some View {
        content
            .tint(tintColor.toColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .animation(.default, value: viewModel.files)
            .background(PassColor.backgroundNorm.toColor)
            .toolbar { ItemDetailToolbar(viewModel: viewModel) }
            .modifier(PermenentlyDeleteItemModifier(item: $viewModel.itemToBeDeleted,
                                                    onDisableAlias: { viewModel.disableAlias() },
                                                    onDelete: {
                                                        dismiss()
                                                        viewModel.permanentlyDelete()
                                                    }))
            .alert("Leave this item?", isPresented: $viewModel.showingLeaveShareAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Leave") {
                    viewModel.leaveShare()
                }
            } message: {
                Text("You will lose access to this item and its details. Do you want to continue?")
            }
            .alert("Move this item", isPresented: $viewModel.showingVaultMoveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Move") {
                    viewModel.moveToAnotherVault()
                }
            } message: {
                // swiftlint:disable:next line_length
                Text("This item is currently shared. Moving it to another vault will remove access for all other users.")
            }
            .alert("Delete this item", isPresented: $viewModel.deleteShareItemAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.itemToBeDeleted = viewModel.itemContent
                }
            } message: {
                Text("This item is currently shared. Deleting it will remove access for all other users.")
            }
            .fullScreenCover(item: $viewModel.filePreviewMode) { mode in
                FileAttachmentPreview(mode: mode,
                                      primaryTintColor: viewModel.itemContentType.normMajor2Color,
                                      secondaryTintColor: viewModel.itemContentType.normMinor1Color)
            }
            .task {
                await viewModel.fetchAttachments()
            }
            .sheet(isPresented: $viewModel.urlToSave.mappedToBool()) {
                if let url = viewModel.urlToSave {
                    ExportDocumentView(url: url)
                }
            }
            .sheet(isPresented: $viewModel.urlToShare.mappedToBool()) {
                if let url = viewModel.urlToShare {
                    ActivityView(items: [url])
                }
            }
    }
}

extension View {
    func itemDetailSetUp(_ viewModel: BaseItemDetailViewModel) -> some View {
        modifier(ItemDetailSetUpModifier(viewModel: viewModel))
    }
}
