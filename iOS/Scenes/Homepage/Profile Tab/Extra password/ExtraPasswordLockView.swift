//
// ExtraPasswordLockView.swift
// Proton Pass - Created on 06/06/2024.
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

import Client
import DesignSystem
import Entities
import Macro
import ProtonCoreServices
import SwiftUI

struct ExtraPasswordLockView: View {
    @StateObject private var viewModel: ExtraPasswordLockViewModel
    @FocusState private var focused
    @State private var showWrongPasswordError = false
    let email: String
    let username: String
    let onSuccess: () -> Void
    let onFailure: () -> Void

    init(apiServicing: any APIManagerProtocol,
         email: String,
         username: String,
         userId: String,
         onSuccess: @escaping () -> Void,
         onFailure: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: .init(apiServicing: apiServicing, userId: userId))
        self.email = email
        self.username = username
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    var body: some View {
        VStack(alignment: .center) {
            Spacer()

            if let logo = UIImage(named: "LaunchScreenPassLogo") {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 88)
                    .padding(.bottom, 32)
            }

            Text("Enter your extra password")
                .font(.title.bold())
                .foregroundStyle(PassColor.textNorm)
                .multilineTextAlignment(.center)

            Text(email)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(PassColor.textWeak)

            SecureField("Extra password", text: $viewModel.extraPassword)
                .font(.title2)
                .padding(.vertical, 32)
                .focused($focused)
                .multilineTextAlignment(.center)

            Text("Wrong extra password")
                .foregroundStyle(PassColor.passwordInteractionNormMajor2)
                .opacity(showWrongPasswordError ? 1 : 0)

            Spacer()

            DisablableCapsuleTextButton(title: #localized("Unlock"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canProceed,
                                        height: 60,
                                        action: { viewModel.unlock(username) })
        }
        .tint(PassColor.interactionNormMajor1)
        .padding()
        .background(PassColor.backgroundNorm)
        .animation(.default, value: showWrongPasswordError)
        .onAppear { focused = true }
        .onChange(of: viewModel.result) { result in
            if let result { handle(result) }
        }
        .onChange(of: viewModel.extraPassword) { password in
            if showWrongPasswordError {
                showWrongPasswordError = password.isEmpty
            }
        }
        .showSpinner(viewModel.loading)
        .alert("Error occurred",
               isPresented: errorBinding,
               actions: { Button("Cancel", role: .cancel, action: onFailure) },
               message: { Text(viewModel.error?.localizedDescription ?? "") })
    }
}

private extension ExtraPasswordLockView {
    var errorBinding: Binding<Bool> {
        .init(get: { viewModel.error != nil },
              set: { _ in })
    }

    func handle(_ result: ExtraPasswordVerificationResult) {
        switch result {
        case .successful:
            onSuccess()
        case .wrongPassword:
            viewModel.extraPassword = ""
            showWrongPasswordError = true
            focused = true
        case .tooManyAttempts:
            onFailure()
        }
    }
}
