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
import Factory

private let kMaxAttemptCount = 3

enum LocalAuthenticationState: Equatable {
    case noAttempts
    case remainingAttempts(Int)
    case lastAttempt
}

final class LocalAuthenticationViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let delayed: Bool
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let onSuccess: () -> Void
    private let onFailure: () -> Void
    private var cancellables = Set<AnyCancellable>()
    let mode: Mode

    @Published private(set) var state: LocalAuthenticationState = .noAttempts
    /// Only applicable for biometric authentication
    @Published private(set) var error: Error?

    var delayedTime: DispatchTimeInterval {
        delayed ? .milliseconds(200) : .milliseconds(0)
    }

    enum Mode: String {
        case biometric, pin
    }

    init(mode: Mode,
         delayed: Bool,
         onAuth: () -> Void,
         onSuccess: @escaping () -> Void,
         onFailure: @escaping () -> Void) {
        self.mode = mode
        self.delayed = delayed
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        updateStateBasedOnFailedAttemptCount()
        onAuth()

        preferences.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStateBasedOnFailedAttemptCount()
            }
            .store(in: &cancellables)
    }

    func biometricallyAuthenticate() {
        let authenticate = resolve(\SharedUseCasesContainer.authenticateBiometrically)
        Task { @MainActor in
            do {
                let authenticated = try await authenticate(reason: "Please authenticate")
                if authenticated {
                    recordSuccess()
                } else {
                    recordFailure(nil)
                }
            } catch {
                recordFailure(error)
            }
        }
    }

    func checkPinCode(_ enteredPinCode: String) {
        guard let currentPIN = preferences.pinCode else {
            // No PIN code is set before, can't do anything but logging out
            let message = "Can not check PIN code. No PIN code set."
            assertionFailure(message)
            logger.error(message)
            onFailure()
            return
        }
        if currentPIN == enteredPinCode {
            recordSuccess()
        } else {
            recordFailure(nil)
        }
    }

    func logOut() {
        logger.debug("Manual log out")
        onFailure()
    }
}

private extension LocalAuthenticationViewModel {
    func updateStateBasedOnFailedAttemptCount() {
        switch preferences.failedAttemptCount {
        case 0:
            state = .noAttempts
        case kMaxAttemptCount - 1:
            state = .lastAttempt
        default:
            let remainingAttempts = kMaxAttemptCount - preferences.failedAttemptCount
            if remainingAttempts >= 1 {
                state = .remainingAttempts(remainingAttempts)
            } else {
                onFailure()
            }
        }
    }

    func recordFailure(_ error: Error?) {
        preferences.failedAttemptCount += 1

        let logMessage = "\(mode.rawValue) authentication failed. Increased failed attempt count."
        if let error {
            logger.error(logMessage + " Reason \(error)")
        } else {
            logger.error(logMessage)
        }
    }

    func recordSuccess() {
        preferences.failedAttemptCount = 0
        onSuccess()
    }
}
