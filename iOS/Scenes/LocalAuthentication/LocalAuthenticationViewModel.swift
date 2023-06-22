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

private let kMaxAttemptCount = 3

enum LocalAuthenticationState {
    case noAttempts
    case remainingAttempts(Int)
    case lastAttempt
}

final class LocalAuthenticationViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let type: LocalAuthenticationType
    let preferences: Preferences
    let logManager: LogManager

    private let logger: Logger
    private let onSuccess: () -> Void
    private let onFailure: () -> Void
    private var cancellables = Set<AnyCancellable>()

    var state: LocalAuthenticationState {
        switch preferences.failedAttemptCount {
        case 0:
            return .noAttempts
        case kMaxAttemptCount - 1:
            return .lastAttempt
        default:
            let remainingAttempts = kMaxAttemptCount - preferences.failedAttemptCount
            if remainingAttempts >= 1 {
                return .remainingAttempts(remainingAttempts)
            } else {
                return .lastAttempt
            }
        }
    }

    init(type: LocalAuthenticationType,
         preferences: Preferences,
         logManager: LogManager,
         onSuccess: @escaping () -> Void,
         onFailure: @escaping () -> Void) {
        self.type = type
        self.preferences = preferences
        self.logManager = logManager
        self.logger = .init(manager: logManager)
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        preferences.attach(to: self, storeIn: &cancellables)

        preferences.objectWillChange
            .sink { [weak self] _ in
                guard let self else { return }
                if self.preferences.failedAttemptCount >= kMaxAttemptCount {
                    onFailure()
                }
            }
            .store(in: &cancellables)
    }

    func recordFailure(_ error: Error?) {
        preferences.failedAttemptCount += 1

        let logMessage = "Biometric authentication failed. Increased failed attempt count."
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
