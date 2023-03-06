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
    @StateObject private var viewModel: CreateAliasLiteViewModel
    @State private var isShowingAdvancedOptions = false
    let tintColor = ItemContentType.login.tintColor

    init(viewModel: CreateAliasLiteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                VStack(spacing: 8) {
                    aliasAddressSection
                        .padding(.vertical, 30)

                    if isShowingAdvancedOptions {
                        PrefixSuffixSection(prefix: $viewModel.prefix,
                                            prefixManuallyEdited: .constant(false),
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
                }
                .animation(.default, value: viewModel.prefixError)
                .animation(.default, value: isShowingAdvancedOptions)
                .padding(.horizontal)
            }

            HStack(spacing: 16) {
                CapsuleTextButton(title: "Cancel",
                                  titleColor: .textWeak,
                                  backgroundColor: .white.withAlphaComponent(0.08),
                                  disabled: false,
                                  height: 44,
                                  action: { viewModel.onDismiss?() })

                CapsuleTextButton(
                    title: "Confirm",
                    titleColor: .textNorm.resolvedColor(with: .init(userInterfaceStyle: .light)),
                    backgroundColor: tintColor,
                    disabled: viewModel.prefixError != nil,
                    height: 44,
                    action: { viewModel.confirm(); viewModel.onDismiss?() })
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color.passSecondaryBackground)
        .tint(Color(uiColor: tintColor))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 18) {
                    NotchView()
                    Text("You are about to create:")
                        .navigationTitleText()
                }
            }
        }
    }

    @ViewBuilder
    private var aliasAddressSection: some View {
        if viewModel.prefixError != nil {
            Text(viewModel.prefix + viewModel.suffixSelection.selectedSuffixString)
                .multilineTextAlignment(.center)
                .foregroundColor(.notificationError)
        } else {
            Text(viewModel.prefix)
                .font(.title2)
                .fontWeight(.medium) +
            Text(viewModel.suffixSelection.selectedSuffixString)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color(uiColor: tintColor))
        }
    }
}
