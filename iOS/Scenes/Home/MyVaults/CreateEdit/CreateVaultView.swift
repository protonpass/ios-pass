//
// CreateVaultView.swift
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

struct CreateVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateVaultViewModel

    init(viewModel: CreateVaultViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TextField("", text: $viewModel.name)
                    TextField("", text: $viewModel.note)
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: dismiss.callAsFunction) {
                Text("Cancel")
            }
            .foregroundColor(.primary)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            SpinnerButton(title: "Save",
                          disabled: !viewModel.isSaveable,
                          spinning: viewModel.isCreating,
                          action: viewModel.createVault)
        }
    }
}
