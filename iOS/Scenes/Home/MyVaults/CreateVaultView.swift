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

import SwiftUI
import UIComponents

struct CreateVaultView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CreateVaultViewModel
    @State private var isFocusedOnName = false
    @State private var isFocusedOnNote = false

    init(viewModel: CreateVaultViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                nameInputView
                noteInputView
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .disabled(viewModel.isLoading)
    }

    private var nameInputView: some View {
        UserInputContainerView(title: "Name",
                               isFocused: isFocusedOnName) {
            UserInputContentSingleLineView(
                text: $viewModel.name,
                isFocused: $isFocusedOnName,
                placeholder: "Vault name")
        }
    }

    private var noteInputView: some View {
        UserInputContainerView(title: "Note",
                               isFocused: isFocusedOnNote) {
            UserInputContentMultilineView(
                text: $viewModel.note,
                isFocused: $isFocusedOnNote)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
            })
            .foregroundColor(Color(.label))
        }

        ToolbarItem(placement: .principal) {
            Text("Create new vault")
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.createVault) {
                Text("Save")
                    .fontWeight(.bold)
                    .foregroundColor(.brandNorm)
                    .opacity(viewModel.name.isEmpty ? 0.5 : 1)
            }
            .disabled(viewModel.name.isEmpty)
        }
    }
}
