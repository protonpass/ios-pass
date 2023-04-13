//
// NoteDetailView.swift
// Proton Pass - Created on 07/09/2022.
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
import UIComponents

struct NoteDetailView: View {
    @StateObject private var viewModel: NoteDetailViewModel
    @Namespace private var bottomID

    init(viewModel: NoteDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if viewModel.isShownAsSheet {
            NavigationView {
                realBody
            }
            .navigationViewStyle(.stack)
        } else {
            realBody
        }
    }

    @ViewBuilder
    private var realBody: some View {
        let tintColor = Color(uiColor: ItemContentType.note.normMajor2Color)
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 0) {
                    if #unavailable(iOS 16) {
                        // iOS 15 doesn't render navigation bar without this view
                        // no idea why it only happens to this specific note detail view
                        // tried adding a dummy `Text` but no help.
                        // Only `ItemDetailTitleView` works
                        ItemDetailTitleView(itemContent: viewModel.itemContent, vault: nil)
                            .frame(height: 0)
                            .opacity(0)
                    }

                    TextView(.constant(viewModel.name))
                        .font(.title)
                        .fontWeight(.bold)
                        .isEditable(false)
                        .foregroundColor(PassColor.textNorm)

                    if let vault = viewModel.vault {
                        VaultLabel(vault: vault)
                    }

                    Spacer(minLength: 16)

                    if viewModel.note.isEmpty {
                        Text("Empty note")
                            .placeholderText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        TextView(.constant(viewModel.note))
                            .autoDetectDataTypes(.all)
                            .isEditable(false)
                    }

                    ItemDetailMoreInfoSection(
                        itemContent: viewModel.itemContent,
                        onExpand: { withAnimation { value.scrollTo(bottomID, anchor: .bottom) } })
                    .padding(.top)
                    .id(bottomID)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accentColor(tintColor) // Remove when iOS 15 is dropped
        .tint(tintColor)
        .itemDetailBackground(theme: viewModel.theme)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar {
            ItemDetailToolbar(isShownAsSheet: viewModel.isShownAsSheet,
                              itemContent: viewModel.itemContent,
                              onGoBack: viewModel.goBack,
                              onEdit: viewModel.edit,
                              onMoveToAnotherVault: viewModel.moveToAnotherVault,
                              onMoveToTrash: viewModel.moveToTrash,
                              onRestore: viewModel.restore,
                              onPermanentlyDelete: viewModel.permanentlyDelete)
        }
    }
}
