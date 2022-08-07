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
                                    placeholder: "Login name",
                                    text: $viewModel.title,
                                    contentType: .clearText,
                                    isRequired: false,
                                    trailingView: { EmptyView() })

                    usernameTextField

                    passwordTextField

                    TitledTextField(title: "Website address",
                                    placeholder: "https://",
                                    text: $viewModel.url,
                                    contentType: .clearText,
                                    isRequired: false,
                                    trailingView: { EmptyView() })

                    TitledTextField(title: "Note",
                                    placeholder: "Add note",
                                    text: $viewModel.note,
                                    contentType: .clearText,
                                    isRequired: false,
                                    trailingView: { EmptyView() })
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

    private var usernameTextField: some View {
        TitledTextField(
            title: "Username",
            placeholder: "Add username",
            text: $viewModel.username,
            contentType: .clearText,
            isRequired: false,
            trailingView: {
                Button(action: viewModel.generateAliasAction) {
                    Image(uiImage: IconProvider.arrowsRotate)
                }
                .foregroundColor(.primary)
            }
        )
    }

    private var passwordTextField: some View {
        let toolbar = UIToolbar()
        let btn = UIBarButtonItem(title: "Generate password",
                                  style: .plain,
                                  target: viewModel,
                                  action: #selector(viewModel.generatePasswordAction))
        btn.tintColor = ColorProvider.BrandNorm
        toolbar.items = [.flexibleSpace(), btn, .flexibleSpace()]
        toolbar.barStyle = UIBarStyle.default
        toolbar.sizeToFit()
        return TitledTextField(
            title: "Password",
            placeholder: "Add password",
            text: $viewModel.password,
            contentType: .secureEntry(viewModel.isPasswordSecure, toolbar),
            isRequired: false,
            trailingView: {
                Button(action: {
                    viewModel.isPasswordSecure.toggle()
                }, label: {
                    Image(uiImage: viewModel.isPasswordSecure ?
                          IconProvider.eye : IconProvider.eyeSlash)
                })
                .foregroundColor(.primary)
            }
        )
    }
}

struct CreateLoginView_Previews: PreviewProvider {
    static var previews: some View {
        CreateLoginView(viewModel: .init())
    }
}
