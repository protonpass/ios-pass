//
//
// UserEmailView.swift
// Proton Pass - Created on 19/07/2023.
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
//

import Client
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct UserEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserEmailViewModel()
    private var router = resolve(\RouterContainer.mainNavViewRouter)
    @FocusState private var defaultFocus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 31) {
            Text("Share with")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(PassColor.textNorm.toColor)

            emailTextField

            if case let .new(vault, _) = viewModel.vault {
                vaultRow(vault)
            }

            Spacer()
        }
        .onAppear {
            if #available(iOS 16, *) {
                defaultFocus = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    defaultFocus = true
                }
            }
        }
        .animation(.default, value: viewModel.error)
        .navigate(isActive: $viewModel.goToNextStep, destination: router.navigate(to: .userSharePermission))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(kItemDetailSectionPadding)
        .navigationBarTitleDisplayMode(.inline)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .ignoresSafeArea(.keyboard)
        .navigationModifier()
    }
}

private extension UserEmailView {
    var emailTextField: some View {
        VStack(alignment: .leading) {
            TextField("Email address", text: $viewModel.email)
                .font(.title)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .foregroundColor(PassColor.textNorm.toColor)
                .focused($defaultFocus, equals: true)
                .accentColor(PassColor.interactionNorm.toColor)
                .tint(PassColor.interactionNorm.toColor)

            if let error = viewModel.error {
                Text(error)
                    .font(.callout)
                    .foregroundColor(PassColor.textWeak.toColor)
            }
        }
    }
}

private extension UserEmailView {
    func vaultRow(_ vault: VaultProtobuf) -> some View {
        HStack {
            VaultRow(thumbnail: {
                         CircleButton(icon: vault.display.icon.icon.bigImage,
                                      iconColor: vault.display.color.color.color,
                                      backgroundColor: vault.display.color.color.color
                                          .withAlphaComponent(0.16))
                     },
                     title: vault.name,
                     itemCount: 1,
                     isShared: false,
                     isSelected: false,
                     height: 74)

            Spacer()

            CapsuleTextButton(title: #localized("Customize"),
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              action: { viewModel.customizeVault() })
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, 16)
        .roundedEditableSection()
    }
}

private extension UserEmailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1) {
                viewModel.resetShareInviteInformation()
                dismiss()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isChecking {
                ProgressView()
            } else {
                DisablableCapsuleTextButton(title: #localized("Continue"),
                                            titleColor: PassColor.textInvert,
                                            disableTitleColor: PassColor.textHint,
                                            backgroundColor: PassColor.interactionNormMajor1,
                                            disableBackgroundColor: PassColor.interactionNormMinor1,
                                            disabled: !viewModel.canContinue,
                                            action: { viewModel.saveEmail() })
            }
        }
    }
}

#Preview("UserEmailView Preview") {
    UserEmailView()
}
