//
// CreateEditLoginView.swift
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

import Core
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateEditLoginView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CreateEditLoginViewModel
    @State private var isShowingDiscardAlert = false
    @State private var isFocusedOnTitle = false
    @State private var isFocusedOnUsername = false
    @State private var isFocusedOnPassword = false
    @State private var isFocusedOnURLs = false
    @State private var isFocusedOnNote = false
    @State private var invalidUrls = [String]()

    init(viewModel: CreateEditLoginViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    loginInputView
                    usernameInputView
                    passwordInputView
                    urlsInputView
                    noteInputView
                }
                .padding()
            }
            .toolbar { toolbarContent }
            .navigationBarTitleDisplayMode(.inline)
        }
        .disabled(viewModel.isLoading)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert) {
            presentationMode.wrappedValue.dismiss()
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
            Text(viewModel.navigationBarTitle())
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                validateUrls()
                if invalidUrls.isEmpty {
                    viewModel.save()
                }
            }, label: {
                Text("Save")
                    .fontWeight(.bold)
                    .foregroundColor(Color(ColorProvider.BrandNorm))
            })
        }
    }

    private var loginInputView: some View {
        UserInputContainerView(title: "Title",
                               isFocused: isFocusedOnTitle) {
            UserInputContentSingleLineView(
                text: $viewModel.title,
                isFocused: $isFocusedOnTitle,
                placeholder: "Login name")
        }
    }

    private var usernameInputView: some View {
        UserInputContainerView(title: "Username",
                               isFocused: isFocusedOnUsername) {
            UserInputContentSingleLineWithTrailingView(
                text: $viewModel.username,
                isFocused: $isFocusedOnUsername,
                placeholder: "Add username",
                trailingView: { Image(uiImage: IconProvider.arrowsRotate) },
                trailingAction: viewModel.generateAlias,
                textAutocapitalizationType: .none)
        }
    }

    private var passwordInputView: some View {
        UserInputContainerView(title: "Password",
                               isFocused: isFocusedOnPassword) {
            UserInputContentPasswordView(
                text: $viewModel.password,
                isFocused: $isFocusedOnPassword,
                isSecure: $viewModel.isPasswordSecure,
                onGeneratePassword: viewModel.generatePassword)
        }
    }

    private var urlsInputView: some View {
        UserInputContainerView(title: "Website address",
                               isFocused: isFocusedOnURLs) {
            UserInputContentURLsView(urls: $viewModel.urls,
                                     isFocused: $isFocusedOnURLs,
                                     invalidUrls: $invalidUrls)
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

    private func validateUrls() {
        invalidUrls = viewModel.urls.compactMap { url in
            if url.isEmpty { return nil }
            if URLUtils.Sanitizer.sanitize(url) == nil {
                return url
            }
            return nil
        }
    }
}
