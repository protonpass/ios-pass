//
// CreateLoginView.swift
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

struct CreateLoginView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CreateLoginViewModel

    init(viewModel: CreateLoginViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TitledTextField(title: "Title",
                                    text: $viewModel.title,
                                    placeholder: "Login name")

                    TitledTextField(title: "Username",
                                    text: $viewModel.username,
                                    placeholder: "Add username")

                    TitledTextField(title: "Password",
                                    text: $viewModel.password,
                                    placeholder: "Add password")

                    TitledTextField(title: "Website address",
                                    text: $viewModel.url,
                                    placeholder: "https://")

                    TitledTextField(title: "Note",
                                    text: $viewModel.note,
                                    placeholder: "Add note")
                }
                .padding()
            }
            .toolbar(content: toolbarContent)
            .navigationBarTitleDisplayMode(.inline)
        }
        .disabled(viewModel.isLoading)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
            })
            .foregroundColor(Color(.label))
        }

        ToolbarItem(placement: .principal) {
            Text("Create new login")
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                viewModel.saveAction()
            }, label: {
                Text("Save")
                    .fontWeight(.bold)
                    .foregroundColor(Color(ColorProvider.BrandNorm))
            })
        }
    }
}

struct CreateLoginView_Previews: PreviewProvider {
    static var previews: some View {
        CreateLoginView(viewModel: .init())
    }
}
