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

    /// Why the last prompt was dismissed without reaching a verdict, so no attempt was consumed.
    private(set) var promptDismissal: LAError.Code?

    /// The credential was right but finishing the unlock failed, so no attempt was consumed.
    private(set) var completionFailed = false

    // Automatic keyboard avoidance is broken in the app cover, so the view pads for the keyboard itself
    let manuallyAvoidKeyboard: Bool
    let mode: LocalAuthenticationView.Mode
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
    private var becameActiveDuringPrompt = false
    private var pinCheckTask: Task<Void, Never>?

    var isCheckingPinCode: Bool {
        pinCheckTask != nil
    }

    var delayedTime: ContinuousClock.Instant.Duration {
        delayed ? .milliseconds(200) : .milliseconds(0)
    }

    var failureMessage: String? {
        switch state {
        case .exhausted, .noAttempts:
            return nil

        case let .remainingAttempts(count):
            let remaining = #localized("%lld remaining attempt(s)", bundle: .module, count)
            guard mode == .pin, !completionFailed else { return remaining }
            return #localized("Incorrect PIN code.", bundle: .module) + " " + remaining

        case .lastAttempt:
            return #localized("This is your last attempt. You will be logged out after failing to authenticate again.",
                              bundle: .module)
        }
    }

    private var failedAttemptCount: Int {
        preferencesManager.sharedPreferences.value?.failedAttemptCount ?? maxAttemptCount
    }

    init(mode: LocalAuthenticationView.Mode,
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
        // SwiftUI builds and discards a view model on every parent re-render, so init must not call
        // `onFailure`: see `logOutIfAttemptsExhausted`.
        state = .init(failedAttemptCount: failedAttemptCount, maxAttemptCount: maxAttemptCount)

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
                let retry = becameActiveDuringPrompt && promptDismissal == .notInteractive
                becameActiveDuringPrompt = false
                biometricCheckTask = nil
                if retry {
                    biometricallyAuthenticate()
                }
            }
            promptDismissal = nil
            completionFailed = false
            do {
                let policy = getSharedPreferences().localAuthenticationPolicy
                let authenticated = try await authenticate(policy: policy,
                                                           reason: #localized("Please authenticate",
                                                                              bundle: .module))
                if authenticated {
                    await recordSuccess()
                } else {
                    await recordFailure(nil)
                }
            } catch PassError.biometricChange {
                // swiftlint:disable:next line_length
                onFailure(#localized("We have detected a change in your biometric authentication settings. For security reasons, you have been logged out.",
                                     bundle: .module))
            } catch let error as LAError where error.reachedNoVerdict {
                promptDismissal = error.code
                logger.warning("\(mode) prompt dismissed without a verdict. \(error)")
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
            completionFailed = false
            guard let currentPIN = getSharedPreferences().pinCode else {
                // No PIN code is set before, can't do anything but logging out
                let message = "Can not check PIN code. No PIN code set."
                assertionFailure(message)
                logger.error(message)
                onFailure(nil)
                return
            }
            if currentPIN == enteredPinCode {
                await recordSuccess()
            } else {
                await recordFailure(nil)
            }
        }
    }

    func appDidBecomeActive() {
        guard case .noAttempts = state else { return }
        guard biometricCheckTask == nil else {
            becameActiveDuringPrompt = true
            return
        }
        if promptDismissal != nil {
            biometricallyAuthenticate()
        }
    }

    func logOut() {
        logger.debug("Manual log out")
        onFailure(nil)
    }

    func logOutIfAttemptsExhausted() {
        if case .exhausted = state {
            onFailure(nil)
        }
    }
}

private extension LocalAuthenticationViewModel {
    func updateStateBasedOnFailedAttemptCount() {
        state = .init(failedAttemptCount: failedAttemptCount, maxAttemptCount: maxAttemptCount)
        logOutIfAttemptsExhausted()
    }

    func recordFailure(_ error: (any Error)?) async {
        do {
            try await updateSharedPreferences(\.failedAttemptCount, value: failedAttemptCount + 1)

            let logMessage = "\(mode) authentication failed. Increased failed attempt count."
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

    func recordSuccess() async {
        do {
            try await updateSharedPreferences(\.failedAttemptCount, value: 0)
            try await onSuccess()
        } catch {
            // The credential was right, so neither consume an attempt nor log out: let the user retry
            logger.error("\(mode) authentication succeeded but could not be completed. \(error)")
            completionFailed = true
        }
    }
}
