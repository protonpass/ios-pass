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
import Entities
import Factory
import Foundation
import Macro

@MainActor
final class SetPINCodeViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    enum State {
        case definition, confirmation
    }

    enum ValidationError: Error {
        case notMatched
    }

    @Published private(set) var state: SetPINCodeViewModel.State = .definition
    @Published private(set) var error: ValidationError?
    @Published private(set) var pinIsSet = false
    @Published var definedPIN = ""
    @Published var confirmedPIN = ""

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let updateSharedPreferences = resolve(\SharedUseCasesContainer.updateSharedPreferences)
    private var cancellables = Set<AnyCancellable>()

    var actionNotAllowed: Bool {
        // Always disallow when error occurs
        guard error == nil else { return true }
        switch state {
        case .definition:
            return isInvalid(pin: definedPIN)
        case .confirmation:
            return isInvalid(pin: confirmedPIN)
        }
    }

    init() {
        // Remove error as soon as users edit something
        Publishers
            .CombineLatest($definedPIN, $confirmedPIN)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                error = nil
            }
            .store(in: &cancellables)
    }
}

extension SetPINCodeViewModel {
    func action() {
        switch state {
        case .definition:
            state = .confirmation

        case .confirmation:
            if confirmedPIN == definedPIN {
                set(pinCode: definedPIN)
            } else {
                error = .notMatched
            }
        }
    }
}

private extension SetPINCodeViewModel {
    func isInvalid(pin: String) -> Bool {
        let minLength = Constants.PINCode.minLength
        let maxLength = Constants.PINCode.maxLength
        return pin.isEmpty || !(minLength...maxLength).contains(pin.count)
    }

    func set(pinCode: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await updateSharedPreferences(\.localAuthenticationMethod, value: .pin)
                try await updateSharedPreferences(\.pinCode, value: pinCode)
                pinIsSet = true
                router.display(element: .successMessage(#localized("PIN code set"),
                                                        config: .init(dismissBeforeShowing: true)))
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

extension SetPINCodeViewModel.State {
    var title: String {
        switch self {
        case .definition:
            #localized("Set PIN code")
        case .confirmation:
            #localized("Repeat PIN code")
        }
    }

    var description: String {
        switch self {
        case .definition:
            #localized("Unlock the app with this code")
        case .confirmation:
            #localized("Type your PIN again to confirm")
        }
    }

    var placeholder: String {
        switch self {
        case .definition:
            #localized("Enter PIN code")
        case .confirmation:
            #localized("Repeat PIN code")
        }
    }

    var actionTitle: String {
        switch self {
        case .definition:
            #localized("Continue")
        case .confirmation:
            #localized("Set PIN code")
        }
    }
}

extension SetPINCodeViewModel.ValidationError {
    var description: String {
        switch self {
        case .notMatched:
            #localized("PINs not matched")
        }
    }
}
