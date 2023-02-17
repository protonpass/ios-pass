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
    let tintColor = ItemContentType.login.tintColor

    init(viewModel: CreateAliasLiteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                ScrollView {
                    VStack {
                        aliasAddressSection
                            .padding(.vertical)
                        prefixSuffixSection
                        mailboxesSection
                        Spacer()
                    }
                    .animation(.default, value: viewModel.prefixError)
                }

                HStack {
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
                .padding(.bottom)
            }
            .padding(.horizontal)
            .tint(Color(uiColor: tintColor))
            .navigationBarTitleDisplayMode(.inline)
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
        .navigationViewStyle(.stack)
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

    private var prefixSuffixSection: some View {
        VStack(alignment: .leading, spacing: kItemDetailSectionPadding) {
            prefixRow
            Divider()
            suffixRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedEditableSection()
    }

    private var prefixRow: some View {
        VStack(alignment: .leading) {
            Text("Prefix")
                .sectionTitleText()
            TextField("Add a prefix", text: $viewModel.prefix)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, kItemDetailSectionPadding)
    }

    private var suffixRow: some View {
        Menu(content: {
            ForEach(viewModel.suffixSelection.suffixes, id: \.suffix) { suffix in
                Button(action: {
                    viewModel.suffixSelection.selectedSuffix = suffix
                }, label: {
                    Label(title: {
                        Text(suffix.suffix)
                    }, icon: {
                        if suffix.suffix == viewModel.suffixSelection.selectedSuffix?.suffix {
                            Image(systemName: "checkmark")
                        }
                    })
                })
            }
        }, label: {
            HStack {
                VStack(alignment: .leading) {
                    Text("Suffix")
                        .sectionTitleText()
                    Text(viewModel.suffixSelection.selectedSuffix?.suffix ?? "")
                        .sectionContentText()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                ItemDetailSectionIcon(icon: IconProvider.chevronDown, color: .textWeak)
            }
            .padding(.horizontal, kItemDetailSectionPadding)
            .transaction { transaction in
                transaction.animation = nil
            }
        })
    }

    private var mailboxesSection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.forward, color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Forwarded to")
                    .sectionTitleText()
                Text(viewModel.mailboxes)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ItemDetailSectionIcon(icon: IconProvider.chevronDown,
                                  color: .textWeak)
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
        .contentShape(Rectangle())
        .onTapGesture(perform: viewModel.showMailboxSelection)
    }
}
