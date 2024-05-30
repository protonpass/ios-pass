//
// SetExtraPasswordView.swift
// Proton Pass - Created on 30/05/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct SetExtraPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SetExtraPasswordViewModel()
    @FocusState private var focused

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            VStack {
                SecureField("Extra password",
                            text: $viewModel.extraPassword,
                            prompt: Text(viewModel.state.placeholder))
                    .focused($focused)
                PassDivider()
                    .padding(.vertical)
                // swiftlint:disable:next line_length
                Text("You will be asked for this password during login and when switching from another Proton app to Proton Pass on web.")
                    .foregroundStyle(PassColor.textWeak.toColor)
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(viewModel.state.navigationTitle)
        .toolbar { toolbarContent }
        .animation(.default, value: viewModel.canContinue)
        .animation(.default, value: viewModel.state)
        .tint(PassColor.interactionNormMajor1.toColor)
        .onChange(of: viewModel.canSetExtraPassword) { _ in
            focused = true
        }
        .navigationStackEmbeded()
        .alert("Set extra password",
               isPresented: $viewModel.showLogOutAlert,
               actions: {
                   Button(action: { viewModel.proceedSetUp() },
                          label: { Text("Confirm") })
                   Button(role: .cancel, label: { Text("Cancel") })
               },
               message: {
                   Text("You will be logged out and will have to log in again on all of your devices.")
               })
        .alert("Confirm your Proton password",
               isPresented: $viewModel.showProtonPasswordConfirmationAlert,
               actions: {
                   SecureField("Proton password", text: $viewModel.protonPassword)
                   Button(action: { viewModel.verifyProtonPassword() },
                          label: { Text("Confirm") })
                   Button(role: .cancel,
                          action: dismiss.callAsFunction,
                          label: { Text("Cancel") })
               })
        .alert("Error occured",
               isPresented: $viewModel.showWrongProtonPasswordAlert,
               actions: {
                   Button(action: { viewModel.retryVerifyingProtonPassword() },
                          label: { Text("Try again") })
                   Button(role: .cancel, label: { Text("Cancel") })
               },
               message: { Text("Wrong Proton password") })
    }
}

private extension SetExtraPasswordView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Continue"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canContinue,
                                        action: { viewModel.continue() })
        }
    }
}
