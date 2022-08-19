//
// CreateNoteView.swift
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

struct CreateNoteView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CreateNoteViewModel
    @State private var isFocusedOnName = false
    @State private var isFocusedOnNote = false

    init(viewModel: CreateNoteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                nameInputView
                noteInputView
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .disabled(viewModel.isLoading)
    }

    private var nameInputView: some View {
        UserInputContainerView(title: "Note name",
                               isFocused: isFocusedOnName) {
            UserInputContentSingleLineView(
                text: $viewModel.name,
                isFocused: $isFocusedOnName,
                placeholder: "Title")
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
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
            })
            .foregroundColor(Color(.label))
        }

        ToolbarItem(placement: .principal) {
            Text("Create new note")
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.saveAction) {
                Text("Save")
                    .fontWeight(.bold)
                    .foregroundColor(Color(ColorProvider.BrandNorm))
            }
        }
    }
}
