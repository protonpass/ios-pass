//
// EnableExtraPasswordView.swift
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

struct EnableExtraPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EnableExtraPasswordViewModel()
    @FocusState private var focused
    @State private var showPassword = false
    let onProtonPasswordVerificationFailure: () -> Void
    let onExtraPasswordEnabled: () -> Void

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            VStack(alignment: .leading) {
                HStack {
                    if showPassword {
                        TextField("Extra password",
                                  text: $viewModel.extraPassword,
                                  prompt: Text(viewModel.state.placeholder))
                            .focused($focused)
                    } else {
                        SecureField("Extra password",
                                    text: $viewModel.extraPassword,
                                    prompt: Text(viewModel.state.placeholder))
                            .focused($focused)
                    }

                    SwiftUIImage(image: showPassword ? IconProvider.eyeSlash : IconProvider.eye,
                                 width: 24,
                                 tintColor: viewModel.extraPassword.isEmpty ?
                                     PassColor.textWeak : PassColor.interactionNormMajor1)
                        .buttonEmbeded { showPassword.toggle() }
                }
                .animation(.default, value: showPassword)

                PassDivider()
                    .padding(.vertical)

                // swiftlint:disable:next line_length
                Text("You will be asked for this password during login and when switching from another Proton app to Proton Pass on web.")
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .padding(.bottom)

                Text("Caution: You won’t be able to access your Pass account if you lose this password.")
                    .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)

                Spacer()
            }
            .padding()
            .opacity(viewModel.canSetExtraPassword ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(viewModel.state.navigationTitle)
        .toolbar { toolbarContent }
        .animation(.default, value: viewModel.canSetExtraPassword)
        .animation(.default, value: viewModel.state)
        .tint(PassColor.interactionNormMajor1.toColor)
        .onChange(of: viewModel.canSetExtraPassword) { _ in
            focused = true
        }
        .onChange(of: viewModel.extraPasswordEnabled) { _ in
            dismiss()
            onExtraPasswordEnabled()
        }
        .onChange(of: viewModel.failedToVerifyProtonPassword) { _ in
            dismiss()
            onProtonPasswordVerificationFailure()
        }
        .showSpinner(viewModel.loading)
        .navigationStackEmbeded()
        .alert("Error occurred",
               isPresented: protonPasswordVerificationErrorBinding,
               actions: { cancelButton },
               message: {
                   Text(viewModel.protonPasswordVerificationError?.localizedDescription ?? "")
               })
        .alert("Error occurred",
               isPresented: enableExtraPasswordErrorBinding,
               actions: {
                   tryAgainButton { viewModel.proceedSetUp() }
                   cancelButton
               },
               message: {
                   Text(viewModel.enableExtraPasswordError?.localizedDescription ?? "")
               })
        .alert("Error occurred",
               isPresented: $viewModel.showWrongProtonPasswordAlert,
               actions: {
                   tryAgainButton { viewModel.retryVerifyingProtonPassword() }
                   cancelButton
               },
               message: { Text("Wrong Proton password") })
        .alert("Set extra password",
               isPresented: $viewModel.showLogOutAlert,
               actions: {
                   Button(action: { viewModel.proceedSetUp() },
                          label: { Text("Confirm") })
                   cancelButton
               },
               message: {
                   Text("You will be logged out and will have to log in again on all of your other devices.")
               })
        .alert("Confirm your Proton password",
               isPresented: $viewModel.showProtonPasswordConfirmationAlert,
               actions: {
                   SecureField("Proton password", text: $viewModel.protonPassword)
                   Button(action: { viewModel.verifyProtonPassword() },
                          label: { Text("Confirm") })
                   cancelButton
               })
    }
}

private extension EnableExtraPasswordView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CapsuleTextButton(title: #localized("Continue"),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNormMajor1,
                              action: { viewModel.continue() })
                .hidden(!viewModel.canSetExtraPassword)
        }
    }

    var cancelButton: some View {
        Button(role: .cancel,
               action: dismiss.callAsFunction,
               label: { Text("Cancel") })
    }

    func tryAgainButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action, label: { Text("Try again") })
    }

    var protonPasswordVerificationErrorBinding: Binding<Bool> {
        .init(get: { viewModel.protonPasswordVerificationError != nil },
              set: { _ in })
    }

    var enableExtraPasswordErrorBinding: Binding<Bool> {
        .init(get: { viewModel.enableExtraPasswordError != nil },
              set: { _ in })
    }
}
