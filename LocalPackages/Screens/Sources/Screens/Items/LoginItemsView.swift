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

import DesignSystem
import Macro
import SwiftUI

public struct LoginItemsView: View {
    @StateObject private var viewModel = LoginItemsViewModel()
    @FocusState private var isFocused
    private let mode: Mode
    private let colorScheme: ColorScheme?
    private let onCreate: () -> Void
    private let onCancel: () -> Void

    public init(mode: Mode,
                colorScheme: ColorScheme?,
                onCreate: @escaping () -> Void,
                onCancel: @escaping () -> Void) {
        self.mode = mode
        self.colorScheme = colorScheme
        self.onCreate = onCreate
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack {
            searchBar

            VStack {
                title
                description
                Spacer()
            }
            .scrollViewEmbeded()

            if mode.allowCreation {
                createButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(PassColor.backgroundNorm.toColor)
        .colorScheme(colorScheme)
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
            .font(.title3.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var description: some View {
        Text(mode.description)
            .foregroundStyle(PassColor.textNorm.toColor)
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
