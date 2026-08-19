//
// LocalAuthenticationViewModel.swift
// Proton Pass - Created on 18/08/2026.
// Copyright (c) 2026 Proton Technologies AG
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
// LocalAuthenticationViewModel.swift
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

import Combine
import Core
import DIComposition
import Entities
import FactoryKit
import Foundation
import LocalAuthentication
import Macro

@Observable
@MainActor
final class LocalAuthenticationViewModel: DeinitPrintable {
    private(set) var state: LocalAuthenticationState = .noAttempts

    /// The last prompt was dismissed without reaching a verdict, so no attempt was consumed and
    /// nothing will re-prompt on its own. Drives the retry button.
    private(set) var promptDismissed = false

    // Only applicable to app cover flow because local authentication process is wrapped inside a view modifier
    // which is applied to a SwiftUI view wrapped inside a UIHostingViewController
    // and somehow automatic keyboard avoidance is broken so we manually avoid keyboard here
    let manuallyAvoidKeyboard: Bool
    let mode: LocalAuthenticationMethod
    let onAuth: () -> Void

    private let delayed: Bool
    private let onSuccess: () async throws -> Void
    private let onFailure: (String?) -> Void

    private let authenticate = dependency(\UseCasesContainer.authenticateBiometrically)
    private let getSharedPreferences = dependency(\UseCasesContainer.getSharedPreferences)
    private let updateSharedPreferences = dependency(\UseCasesContainer.updateSharedPreferences)
    private let preferencesManager = dependency(\ToolingContainer.preferencesManager)
    private let logger = dependency(\ToolingContainer.logger)

    private let maxAttemptCount = 3

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private var biometricCheckTask: Task<Void, Never>?
    @ObservationIgnored
    private var pinCheckTask: Task<Void, Never>?

    var delayedTime: ContinuousClock.Instant.Duration {
        delayed ? .milliseconds(200) : .milliseconds(0)
    }

    private var failedAttemptCount: Int {
        preferencesManager.sharedPreferences.value?.failedAttemptCount ?? maxAttemptCount
    }

    init(mode: LocalAuthenticationMethod,
         delayed: Bool,
         manuallyAvoidKeyboard: Bool,
         onAuth: @escaping () -> Void,
         onSuccess: @escaping () async throws -> Void,
         onFailure: @escaping (String?) -> Void) {
        self.mode = mode
        self.delayed = delayed
        self.manuallyAvoidKeyboard = manuallyAvoidKeyboard
        self.onAuth = onAuth
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        updateStateBasedOnFailedAttemptCount()

        preferencesManager
            .sharedPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.failedAttemptCount)
            .sink { [weak self] _ in
                guard let self else { return }
                updateStateBasedOnFailedAttemptCount()
            }
            .store(in: &cancellables)
    }

    deinit { print(deinitMessage) }

    func biometricallyAuthenticate() {
        guard biometricCheckTask == nil else { return }
        biometricCheckTask = Task { [weak self] in
            guard let self else { return }
            defer {
                biometricCheckTask = nil
            }
            promptDismissed = false
            do {
                let policy = getSharedPreferences().localAuthenticationPolicy
                let authenticated = try await authenticate(policy: policy,
                                                           reason: #localized("Please authenticate"))
                if authenticated {
                    try await recordSuccess()
                } else {
                    await recordFailure(nil)
                }
            } catch PassError.biometricChange {
                // swiftlint:disable:next line_length
                onFailure(#localized("We have detected a change in your biometric authentication settings. For security reasons, you have been logged out."))
            } catch let error as LAError where error.reachedNoVerdict {
                promptDismissed = true
                logger.warning("\(mode.type) prompt dismissed without a verdict. \(error)")
            } catch {
                await recordFailure(error)
            }
        }
    }

    func checkPinCode(_ enteredPinCode: String) {
        guard pinCheckTask == nil else { return }
        pinCheckTask = Task { [weak self] in
            guard let self else { return }
            defer {
                pinCheckTask = nil
            }
            guard let currentPIN = getSharedPreferences().pinCode else {
                // No PIN code is set before, can't do anything but logging out
                let message = "Can not check PIN code. No PIN code set."
                assertionFailure(message)
                logger.error(message)
                onFailure(nil)
                return
            }
            if currentPIN == enteredPinCode {
                do {
                    try await recordSuccess()
                } catch {
                    await recordFailure(error)
                }
            } else {
                await recordFailure(nil)
            }
        }
    }

    func logOut() {
        logger.debug("Manual log out")
        onFailure(nil)
    }
}

private extension LocalAuthenticationViewModel {
    func updateStateBasedOnFailedAttemptCount() {
        let newState = LocalAuthenticationState(failedAttemptCount: failedAttemptCount,
                                                maxAttemptCount: maxAttemptCount)
        if case .exhausted = newState {
            onFailure(nil)
        } else {
            state = newState
        }
    }

    func recordFailure(_ error: (any Error)?) async {
        do {
            try await updateSharedPreferences(\.failedAttemptCount, value: failedAttemptCount + 1)

            let logMessage = "\(mode.type) authentication failed. Increased failed attempt count."
            if let error {
                logger.error(logMessage + " Reason \(error)")
            } else {
                logger.error(logMessage)
            }
        } catch {
            // Failed to even record error, something's very wrong. Just log out.
            onFailure(nil)
        }
    }

    func recordSuccess() async throws {
        try await updateSharedPreferences(\.failedAttemptCount, value: 0)
        try await onSuccess()
    }
}
