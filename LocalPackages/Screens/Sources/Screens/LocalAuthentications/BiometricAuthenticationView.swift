//
// BiometricAuthenticationView.swift
// Proton Pass - Created on 22/06/2023.
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

import DesignSystem
import LocalAuthentication
import Macro
import SwiftUI

struct BiometricAuthenticationView: View {
    @Bindable var viewModel: LocalAuthenticationViewModel

    var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()

                passLogo

                if let failureMessage = viewModel.failureMessage {
                    Text(verbatim: failureMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PassColor.textNorm)
                    UnavailabilityMessage(message: statusMessage)
                    retryButton
                        .padding(.top)
                } else if viewModel.state == .noAttempts,
                          viewModel.promptDismissal != nil || viewModel.completionFailed {
                    Text(verbatim: statusMessage ?? #localized("Please authenticate", bundle: .module))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PassColor.textNorm)
                    retryButton
                        .padding(.top)
                }

                Spacer()
                    .frame(height: proxy.size.height / 2)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                guard case .noAttempts = viewModel.state,
                      await (try? Task.sleep(for: viewModel.delayedTime)) != nil else { return }
                viewModel.onAuth()
                viewModel.biometricallyAuthenticate()
            }
            // Covers -1004 from prompting before we were frontmost
            .onReceive(UIApplication.didBecomeActiveNotification, perform: viewModel.appDidBecomeActive)
        }
    }
}

private extension BiometricAuthenticationView {
    var statusMessage: String? {
        if viewModel.completionFailed {
            return #localized("Error occurred", bundle: .module)
        }
        return viewModel.promptDismissal?.unavailabilityMessage
    }

    var passLogo: some View {
        PassIcon.passIcon
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 160)
    }

    var retryButton: some View {
        Button(action: viewModel.biometricallyAuthenticate) {
            Text("Try again", bundle: .module)
                .foregroundStyle(PassColor.interactionNormMajor2)
        }
    }
}

private struct UnavailabilityMessage: View {
    let message: String?

    var body: some View {
        if let message {
            Text(verbatim: message)
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm)
                .padding(.top)
        }
    }
}

private extension LAError.Code {
    var unavailabilityMessage: String? {
        switch self {
        case .biometryLockout:
            #localized("Biometrics are locked. Unlock your device with your passcode, then try again.",
                       bundle: .module)

        case .biometryNotAvailable:
            #localized("Biometrics are not available. Allow them for Proton Pass in Settings, then try again.",
                       bundle: .module)

        case .biometryNotEnrolled:
            #localized("Biometrics are not set up on this device. Set them up in Settings, then try again.",
                       bundle: .module)

        default:
            nil
        }
    }
}
