//
// CreateItemView.swift
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

struct CreateItemView: View {
    @Environment(\.presentationMode) private var presentationMode
    private let viewModel: CreateItemViewModel

    init(viewModel: CreateItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                GenericItemView(item: CreateNewItemOption.login.toGenericItem(),
                                action: { viewModel.select(option: .login) },
                                trailingView: { EmptyView() })

                GenericItemView(item: CreateNewItemOption.alias.toGenericItem(),
                                action: { viewModel.select(option: .alias) },
                                trailingView: { EmptyView() })

                GenericItemView(item: CreateNewItemOption.note.toGenericItem(),
                                action: { viewModel.select(option: .note) },
                                trailingView: { EmptyView() })

                GenericItemView(item: CreateNewItemOption.password.toGenericItem(),
                                showDivider: false,
                                action: { viewModel.select(option: .password) },
                                trailingView: { EmptyView() })

                Spacer()
            }
            .navigationTitle("New...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(uiImage: IconProvider.cross)
            })
            .foregroundColor(Color(.label))
        }
    }
}
