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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct NoteDetailView: View {
    @StateObject private var viewModel: NoteDetailViewModel
    private let tintColor = UIColor.systemYellow

    init(viewModel: NoteDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ItemDetailTitleView(color: tintColor,
                                    icon: .image(IconProvider.note),
                                    title: viewModel.name)
                if viewModel.note.isEmpty {
                    Text("Empty note")
                        .placeholderText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(viewModel.note)
                        .sectionContentText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ItemDetailFooterView(createTime: viewModel.createTime,
                                     modifyTime: viewModel.modifyTime)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         color: tintColor,
                         action: viewModel.goBack)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            switch viewModel.itemContent.item.itemState {
            case .active:
                HStack {
                    Button(action: viewModel.edit) {
                        Text("Edit")
                            .foregroundColor(.interactionNorm)
                    }

                    CapsuleButton(icon: IconProvider.threeDotsVertical,
                                  color: tintColor,
                                  action: {})
                }

            case .trashed:
                Button(action: viewModel.restore) {
                    Text("Restore")
                        .foregroundColor(.interactionNorm)
                }
            }
        }
    }
}
