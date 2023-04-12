//
// CreateAliasLiteView.swift
// Proton Pass - Created on 16/02/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateAliasLiteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateAliasLiteViewModel
    @State private var isShowingAdvancedOptions = false

    init(viewModel: CreateAliasLiteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            // ZStack instead of VStack as root because of SwiftUI bug
            // If the ScrollView is contained in a VStack
            // the navigation bar background is not rendered
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 8) {
                        aliasAddressSection
                            .padding(.vertical, 30)

                        if isShowingAdvancedOptions {
                            PrefixSuffixSection(prefix: $viewModel.prefix,
                                                prefixManuallyEdited: .constant(false),
                                                isLoading: false,
                                                tintColor: ItemContentType.login.normMajor1Color,
                                                suffixSelection: viewModel.suffixSelection,
                                                prefixError: viewModel.prefixError)
                        }

                        MailboxSection(mailboxSelection: viewModel.mailboxSelection)
                            .onTapGesture(perform: viewModel.showMailboxSelection)

                        if !isShowingAdvancedOptions {
                            AdvancedOptionsSection(isShowingAdvancedOptions: $isShowingAdvancedOptions)
                                .padding(.vertical)
                        }

                        Spacer()

                        buttons
                            .opacity(0)
                            .disabled(true)
                    }
                    .animation(.default, value: viewModel.prefixError)
                    .animation(.default, value: isShowingAdvancedOptions)
                    .padding(.horizontal)
                }

                buttons
                    .padding()
                    .background(Color(uiColor: PassColor.backgroundWeak))
            }
            .background(Color(uiColor: PassColor.backgroundWeak))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavigationTitleWithHandle(title: "You are about to create")
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var aliasAddressSection: some View {
        if viewModel.prefixError != nil {
            Text(viewModel.prefix + viewModel.suffixSelection.selectedSuffixString)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(uiColor: PassColor.signalDanger))
        } else {
            Text(viewModel.prefix)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color(uiColor: PassColor.textNorm)) +
            Text(viewModel.suffixSelection.selectedSuffixString)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color(uiColor: PassColor.loginInteractionNormMajor1))
        }
    }

    private var buttons: some View {
        HStack(spacing: 16) {
            CapsuleTextButton(title: "Cancel",
                              titleColor: PassColor.textWeak,
                              backgroundColor: PassColor.textDisabled,
                              height: 44,
                              action: dismiss.callAsFunction)

            DisablableCapsuleTextButton(title: "Confirm",
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.loginInteractionNormMajor1,
                                        disableBackgroundColor: PassColor.loginInteractionNormMinor1,
                                        disabled: viewModel.prefixError != nil,
                                        height: 44,
                                        action: { viewModel.confirm(); dismiss() })
        }
    }
}
