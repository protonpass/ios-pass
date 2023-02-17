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
    let tintColor = ItemContentType.login.tintColor

    init(viewModel: CreateAliasLiteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    aliasAddressSection
                        .padding(.vertical, 30)

                    if isShowingAdvancedOptions {
                        PrefixSuffixSection(prefix: $viewModel.prefix,
                                            suffixSelection: viewModel.suffixSelection)
                    }

                    MailboxSection(mailboxSelection: viewModel.mailboxSelection)
                        .onTapGesture(perform: viewModel.showMailboxSelection)

                    if !isShowingAdvancedOptions {
                        advancedOptionsSection
                            .padding(.vertical)
                    }

                    Spacer()
                }
                .animation(.default, value: viewModel.prefixError)
                .animation(.default, value: isShowingAdvancedOptions)
            }

            HStack(spacing: 16) {
                CapsuleTextButton(title: "Cancel",
                                  titleColor: .textWeak,
                                  backgroundColor: .white.withAlphaComponent(0.08),
                                  disabled: false,
                                  height: 44,
                                  action: dismiss.callAsFunction)

                CapsuleTextButton(
                    title: "Confirm",
                    titleColor: .textNorm.resolvedColor(with: .init(userInterfaceStyle: .light)),
                    backgroundColor: tintColor,
                    disabled: viewModel.prefixError != nil,
                    height: 44,
                    action: { dismiss(); viewModel.confirm() })
            }
            .padding([.horizontal, .bottom])
        }
        .padding(.horizontal)
        .tint(Color(uiColor: tintColor))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    NotchView()
                    Text("You are about to create:")
                        .navigationTitleText()
                }
            }
        }
    }

    @ViewBuilder
    private var aliasAddressSection: some View {
        if let prefixError = viewModel.prefixError {
            Text(prefixError.localizedDescription)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        } else {
            Text(viewModel.prefix)
                .font(.title2)
                .fontWeight(.medium) +
            Text(viewModel.suffixSelection.selectedSuffix?.suffix ?? "")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color(uiColor: tintColor))
        }
    }

    private var advancedOptionsSection: some View {
        Button(action: {
            isShowingAdvancedOptions.toggle()
        }, label: {
            Label(title: {
                Text("Show advanced options")
                    .font(.callout)
            }, icon: {
                Image(uiImage: IconProvider.cogWheel)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16)
            })
            .foregroundColor(.textWeak)
            .frame(maxWidth: .infinity, alignment: .trailing)
        })
    }
}
