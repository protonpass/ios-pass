//
//
// AddCustomEmailView.swift
// Proton Pass - Created on 18/04/2024.
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
//

import DesignSystem
import Entities
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct AddCustomEmailView: View {
    @StateObject var viewModel: AddCustomEmailViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused
    @State private var showErrorAlert = false
    @State private var showResendCodeButton = false

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding * 2) {
            if viewModel.isVerificationMode {
                Text("We sent a verification code to \(viewModel.email). Enter it below:")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                TextField("Code", text: $viewModel.code)
                    .focused($focused)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    // Trick iOS into not suggesting one-time code autofill
                    .textContentType(.jobTitle)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .tint(PassColor.interactionNorm.toColor)
                    .frame(height: 64)
            } else {
                TextField("Email address", text: $viewModel.email)
                    .focused($focused)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .tint(PassColor.interactionNorm.toColor)
                    .frame(height: 64)
            }

            DisablableCapsuleTextButton(title: #localized("Continue"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canContinue,
                                        height: 44,
                                        action: { viewModel.nextStep() })

            if viewModel.isVerificationMode {
                Label("Haven't received the code?",
                      systemImage: showResendCodeButton ? "chevron.up" : "chevron.down")
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .labelStyle(.rightIcon)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .buttonEmbeded {
                        showResendCodeButton.toggle()
                        focused = !showResendCodeButton
                    }

                if showResendCodeButton {
                    Text(viewModel.type.resendCodeMessage)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .tint(PassColor.interactionNormMajor1.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .environment(\.openURL, OpenURLAction(handler: handleURL))
                }
            }

            Spacer()
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .scrollViewEmbeded()
        .animation(.default, value: viewModel.canContinue)
        .animation(.default, value: viewModel.isVerificationMode)
        .animation(.default, value: showResendCodeButton)
        .toolbar { toolbarContent }
        .background(PassColor.backgroundNorm.toColor)
        .onChange(of: viewModel.finishedVerification) { isVerificationFinished in
            guard isVerificationFinished else {
                return
            }
            dismiss()
        }
        .onReceive(viewModel.$verificationError) { error in
            showErrorAlert = error != nil
        }
        .alert("Error occurred",
               isPresented: $showErrorAlert,
               actions: {
                   Button(action: dismiss.callAsFunction) {
                       Text("OK")
                   }
               },
               message: {
                   if let message = viewModel.verificationError?.localizedDescription {
                       Text(message)
                   }
               })
        .onAppear { focused = true }
        .navigationTitle(viewModel.isVerificationMode ? "Confirm your email" : viewModel.type.title)
        .navigationStackEmbeded()
    }
}

private extension AddCustomEmailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }
    }

    func handleURL(_: URL) -> OpenURLAction.Result {
        viewModel.sendVerificationCode()
        return .handled
    }
}

private extension ValidationEmailType {
    var title: LocalizedStringKey {
        switch self {
        case .customEmail:
            "Custom email monitoring"
        case .mailbox:
            "Add mailbox"
        }
    }

    // swiftlint:disable line_length
    var resendCodeMessage: LocalizedStringKey {
        switch self {
        case .customEmail:
            "Please check in your Spam for an email called \"Please confirm your email address for Proton Pass\"\n\nIf you can't find such email, you can [request a new code](https://proton.me)."
        case let .mailbox(email):
            "Please check in your Spam for an email called \"Please confirm your mailbox \(email?.email ?? "")\"\n\nIf you can't find such email, you can [request a new code](https://proton.me)."
        }
    }
    // swiftlint:enable line_length
}
