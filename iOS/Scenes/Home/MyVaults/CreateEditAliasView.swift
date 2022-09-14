//
// CreateEditAliasView.swift
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

import Combine
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateEditAliasView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CreateEditAliasViewModel
    @State private var isFocusedOnTitle = false
    @State private var isFocusedOnPrefix = false
    @State private var isFocusedOnNote = false

    init(viewModel: CreateEditAliasViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    titleInputView
                    aliasInputView
                    mailboxesInputView
                    noteInputView
                }
                .padding()
            }
            .toolbar { toolbarContent }
            .navigationBarTitleDisplayMode(.inline)
        }
        .disabled(viewModel.isLoading)
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

        ToolbarItem(placement: .principal) {
            Text(viewModel.navigationBarTitle())
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

    private var titleInputView: some View {
        UserInputContainerView(title: "Title",
                               isFocused: isFocusedOnTitle) {
            UserInputContentSingleLineView(
                text: $viewModel.title,
                isFocused: $isFocusedOnTitle,
                placeholder: "Alias name")
        }
    }

    private var aliasInputView: some View {
        VStack {
            UserInputContainerView(title: "Alias",
                                   isFocused: isFocusedOnPrefix) {
                UserInputContentSingleLineWithTrailingView(
                    text: $viewModel.prefix,
                    isFocused: $isFocusedOnPrefix,
                    placeholder: "Prefix",
                    trailingView: {
                        Image(uiImage: IconProvider.crossCircleFilled)
                        .foregroundColor(.secondary)
                        .opacity(isFocusedOnPrefix ? 1 : 0)
                        .disabled(!isFocusedOnPrefix)
                    },
                    trailingAction: { viewModel.prefix = "" },
                    textAutocapitalizationType: .none)
            }

            UserInputContainerView(title: nil, isFocused: false) {
                UserInputStaticContentView(text: $viewModel.suffix) {
                    print("OKAY")
                }
            }

            if !viewModel.prefix.isEmpty {
                HStack {
                    Group {
                        Text("You're about to create alias ")
                            .foregroundColor(.secondary) +
                        Text(viewModel.prefix + viewModel.suffix)
                            .foregroundColor(Color(ColorProvider.BrandNorm))
                    }
                    .font(.caption)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(AnyTransition.opacity.animation(.linear(duration: 0.2)))
            }
        }
    }

    private var mailboxesInputView: some View {
        UserInputContainerView(title: "Mailboxes", isFocused: false) {
            UserInputStaticContentView(text: $viewModel.mailbox) {
                print("OKAY")
            }
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
}
