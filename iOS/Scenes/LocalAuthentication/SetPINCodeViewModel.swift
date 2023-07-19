//
// SetPINCodeViewModel.swift
// Proton Pass - Created on 19/07/2023.
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
import SwiftUI

final class SetPINCodeViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    enum State {
        case definition, confirmation
    }

    enum ValidationError: Error {
        case invalidCharacters, notMatched
    }

    @Published private(set) var state: SetPINCodeViewModel.State = .definition
    @Published private(set) var error: ValidationError?
    @Published var definedPIN = ""
    @Published var confirmedPIN = ""

    private let preferences = resolve(\SharedToolingContainer.preferences)
    private var cancellables = Set<AnyCancellable>()
    var onSet: (String) -> Void

    var theme: Theme { preferences.theme }

    var actionNotAllowed: Bool {
        // Always disallow when error occurs
        guard error == nil else { return true }
        let minLength = Constants.PINCode.minLength
        let maxLength = Constants.PINCode.maxLength
        switch state {
        case .definition:
            return definedPIN.isEmpty || !(minLength...maxLength).contains(definedPIN.count)
        case .confirmation:
            return confirmedPIN.isEmpty || !(minLength...maxLength).contains(confirmedPIN.count)
        }
    }

    init(onSet: @escaping (String) -> Void) {
        self.onSet = onSet

        // Remove error as soon as users edit something
        Publishers
            .CombineLatest($definedPIN, $confirmedPIN)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.error = nil
            }
            .store(in: &cancellables)
    }
}

extension SetPINCodeViewModel {
    func action() {
        switch state {
        case .definition:
            if definedPIN.isValid(allowedCharacters: .decimalDigits) {
                state = .confirmation
            } else {
                error = .invalidCharacters
            }

        case .confirmation:
            if confirmedPIN.isValid(allowedCharacters: .decimalDigits) {
                if confirmedPIN == definedPIN {
                    onSet(definedPIN)
                } else {
                    error = .notMatched
                }
            } else {
                error = .invalidCharacters
            }
        }
    }
}

extension SetPINCodeViewModel.State {
    var title: String {
        switch self {
        case .definition:
            return "Set PIN code"
        case .confirmation:
            return "Repeat PIN code"
        }
    }

    var description: String {
        switch self {
        case .definition:
            return "Unlock the app with this code"
        case .confirmation:
            return "Type your PIN again to confirm"
        }
    }

    var placeholder: String {
        switch self {
        case .definition:
            return "Choose a PIN code"
        case .confirmation:
            return "Repeat PIN code"
        }
    }

    var actionTitle: String {
        switch self {
        case .definition:
            return "Continue"
        case .confirmation:
            return "Set PIN code"
        }
    }
}

extension SetPINCodeViewModel.ValidationError {
    var description: String {
        switch self {
        case .invalidCharacters:
            return "PIN must contain only numeric characters (0-9)"
        case .notMatched:
            return "PINs not matched"
        }
    }
}
