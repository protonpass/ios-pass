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

import Core
import SwiftUI
import UIComponents

struct BiometricAuthenticationView: View {
    @StateObject private var authenticator: BiometricAuthenticator
    @ObservedObject private var viewModel: LocalAuthenticationViewModel

    init(viewModel: LocalAuthenticationViewModel) {
        _authenticator = .init(wrappedValue: .init(preferences: viewModel.preferences,
                                                   logManager: viewModel.logManager))
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()

            switch authenticator.biometryTypeState {
            case .idle, .initializing:
                passLogo
                ProgressView()

            case .initialized:
                initializedView

            case let .error(error):
                VStack {
                    passLogo
                    Text(error.localizedDescription)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(uiColor: PassColor.signalDanger))
                }
            }
        }
        .onFirstAppear(perform: authenticator.initializeBiometryType)
    }
}

private extension BiometricAuthenticationView {
    var passLogo: some View {
        Image(uiImage: PassIcon.passIcon)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 160)
    }

    var retryButton: some View {
        Button(action: authenticate) {
            Text("Try again")
                .foregroundColor(PassColor.interactionNormMajor2.toColor)
        }
    }

    func authenticate() {
        Task {
            do {
                if try await authenticator.authenticate(reason: "Please authenticate") {
                    viewModel.recordSuccess()
                } else {
                    viewModel.recordFailure(nil)
                }
            } catch {
                viewModel.recordFailure(error)
            }
        }
    }

    var initializedView: some View {
        GeometryReader { proxy in
            VStack {
                VStack {
                    Spacer()

                    passLogo

                    switch viewModel.state {
                    case .noAttempts:
                        EmptyView()

                    case .lastAttempt:
                        // swiftlint:disable:next line_length
                        Text("This is your last attempt. You will be logged out after failling to authenticate again.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(PassColor.textNorm.toColor)
                        retryButton
                            .padding(.top)

                    case let .remainingAttempts(count):
                        Text("\(count) remaining attempt(s)")
                            .foregroundColor(PassColor.textNorm.toColor)
                        retryButton
                            .padding(.top)
                    }
                }
                Spacer()
                    .frame(height: proxy.size.height / 2)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onFirstAppear {
            if case .noAttempts = viewModel.state {
                // Only automatically prompt for biometric authentication when no attempts were made
                // Otherwise let the users know how many attempts are remaining
                // and let them retry explicitly
                authenticate()
            }
        }
    }
}
