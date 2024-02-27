//
// LoginItemsView.swift
// Proton Pass - Created on 27/02/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import Client
import DesignSystem
import Entities
import Macro
import SwiftUI

public struct LoginItemsView<ItemRow: View>: View {
    @StateObject private var viewModel: LoginItemsViewModel
    @FocusState private var isFocused
    private let mode: Mode
    private let itemRow: (ItemUiModel) -> ItemRow
    private let onCreate: () -> Void
    private let onCancel: () -> Void

    public init(searchableItems: [SearchableItem],
                uiModels: [ItemUiModel],
                mode: Mode,
                itemRow: @escaping (ItemUiModel) -> ItemRow,
                onCreate: @escaping () -> Void,
                onCancel: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: .init(searchableItems: searchableItems,
                                               uiModels: uiModels))
        self.mode = mode
        self.itemRow = itemRow
        self.onCreate = onCreate
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack {
            searchBar

            List {
                title
                    .plainListRow()

                description
                    .plainListRow()
                    .padding(.vertical)

                if !viewModel.uiModels.isEmpty {
                    ForEach(viewModel.uiModels, id: \.id) { item in
                        itemRow(item)
                            .plainListRow()
                    }
                }

                Spacer()
            }
            .listStyle(.plain)
            .padding(.horizontal)

            if mode.allowCreation {
                createButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassColor.backgroundNorm.toColor)
    }
}

private extension LoginItemsView {
    var searchBar: some View {
        SearchBar(query: $viewModel.query,
                  isFocused: $isFocused,
                  placeholder: mode.searchBarPlaceholder,
                  onCancel: onCancel)
    }
}

private extension LoginItemsView {
    var title: some View {
        Text(mode.title)
            .foregroundStyle(PassColor.textNorm.toColor)
            .font(.title.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var description: some View {
        Text(mode.description)
            .foregroundStyle(PassColor.textNorm.toColor)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var createButton: some View {
        CapsuleTextButton(title: #localized("Create login"),
                          titleColor: PassColor.loginInteractionNormMajor2,
                          backgroundColor: PassColor.loginInteractionNormMinor1,
                          height: 52,
                          action: onCreate)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
}
