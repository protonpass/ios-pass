//
// CreateEditNoteView.swift
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

struct CreateEditNoteView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CreateEditNoteViewModel
    @State private var isShowingDiscardAlert = false
    @State private var isFocusedOnName = false
    @State private var isFocusedOnNote = false

    init(viewModel: CreateEditNoteViewModel) {
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
            .toolbar { toolbarContent }
        }
        .disabled(viewModel.isLoading)
        .alert(isPresented: $isShowingDiscardAlert) {
            Alert(title: Text("Discard changes"),
                  message: Text("You will loose all unsaved changes"),
                  primaryButton: .destructive(Text("Discard Changes"),
                                              action: { presentationMode.wrappedValue.dismiss() }),
                  secondaryButton: .default(Text("Keep Editing")))
        }
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
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                if viewModel.isEmpty {
                    presentationMode.wrappedValue.dismiss()
                } else {
                    isShowingDiscardAlert.toggle()
                }
            }, label: {
                Image(uiImage: IconProvider.cross)
            })
            .foregroundColor(Color(.label))
        }

        ToolbarItem(placement: .principal) {
            Text("Create new note")
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.save) {
                Text("Save")
                    .fontWeight(.bold)
                    .foregroundColor(Color(ColorProvider.BrandNorm))
            }
        }
    }
}
