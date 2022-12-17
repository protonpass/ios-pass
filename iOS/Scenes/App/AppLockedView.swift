//
// AppLockedView.swift
// Proton Pass - Created on 21/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

private let kMaxAttemptCount = 3

struct AppLockedView: View {
    @StateObject private var authenticator: BiometricAuthenticator
    @ObservedObject private var preferences: Preferences
    private let delayed: Bool
    private let onSuccess: () -> Void
    private let onFailure: () -> Void

    private var isLastAttempt: Bool { preferences.failedAttemptCount == kMaxAttemptCount - 1 }
    private var remainingAttempts: Int { kMaxAttemptCount - preferences.failedAttemptCount }

    init(preferences: Preferences,
         delayed: Bool,
         onSuccess: @escaping () -> Void,
         onFailure: @escaping () -> Void) {
        self._authenticator = .init(wrappedValue: .init(preferences: preferences))
        self._preferences = .init(wrappedValue: preferences)
        self.delayed = delayed
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    var body: some View {
        ZStack {
            switch authenticator.biometryTypeState {
            case .idle, .initializing:
                lockImage
                ProgressView()

            case .initialized:
                VStack {
                    lockImage
                    if isLastAttempt {
                        // swiftlint:disable:next line_length
                        Text("This is your last attempt. You will be logged out after failling to authenticate again.")
                            .multilineTextAlignment(.center)
                        retryButton
                    } else if preferences.failedAttemptCount > 0 {
                        Text("\(remainingAttempts) remaining attempts")
                        retryButton
                    }
                }
                .padding()
                .task {
                    if preferences.failedAttemptCount == 0 {
                        await authenticate(delayed: delayed)
                    } else if preferences.failedAttemptCount >= kMaxAttemptCount {
                        onFailure()
                    }
                }

            case .error(let error):
                VStack {
                    lockImage
                    Text(error.localizedDescription)
                }
            }
        }
        .onAppear {
            authenticator.initializeBiometryType()
        }
    }

    private var lockImage: some View {
        Image(uiImage: IconProvider.lockFilled)
            .resizable()
            .scaledToFit()
            .foregroundColor(.secondary)
            .frame(maxWidth: 100)
    }

    private var retryButton: some View {
        Button(action: {
            Task {
                await authenticate(delayed: false)
            }
        }, label: {
            Text("Try again")
                .foregroundColor(.brandNorm)
        })
    }

    @MainActor
    func authenticate(delayed: Bool) async {
        guard preferences.failedAttemptCount < kMaxAttemptCount else {
            onFailure()
            return
        }
        defer {
            if preferences.failedAttemptCount >= kMaxAttemptCount {
                onFailure()
            }
        }
        do {
            // Delay is neccessary in AutoFill context in order for the view
            // to get rendered before being able to ask for authentication
            if delayed {
                try await Task.sleep(nanoseconds: 200_000_000)
            }
            let authenticated = try await authenticator.authenticate(reason: "Please authenticate")
            if authenticated {
                preferences.failedAttemptCount = 0
                onSuccess()
            } else {
                preferences.failedAttemptCount += 1
            }
        } catch {
            preferences.failedAttemptCount += 1
        }
    }
}