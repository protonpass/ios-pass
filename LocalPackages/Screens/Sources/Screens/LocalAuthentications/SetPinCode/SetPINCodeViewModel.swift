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

// import Combine
// import Core
// import DIComposition
// import Entities
// import FactoryKit
// import Foundation
// import Macro
//
// @Observable
// @MainActor
// final class SetPINCodeViewModel: DeinitPrintable {
//    private(set) var state: SetPINCodeViewModel.State = .definition
//    private(set) var error: ValidationError?
//    var definedPIN = ""
//    var confirmedPIN = ""
//
//    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
//    private let updateSharedPreferences = dependency(\UseCasesContainer.updateSharedPreferences)
//
//    @ObservationIgnored
//    private var cancellables = Set<AnyCancellable>()
//
//    enum State {
//        case definition, confirmation
//    }
//
//    enum ValidationError: Error {
//        case notMatched
//    }
//
//    var actionNotAllowed: Bool {
//        // Always disallow when error occurs
//        guard error == nil else { return true }
//        switch state {
//        case .definition:
//            return isInvalid(pin: definedPIN)
//
//        case .confirmation:
//            return isInvalid(pin: confirmedPIN)
//        }
//    }
//
//    init() {
//        // Remove error as soon as users edit something
//        Publishers
//            .CombineLatest($definedPIN, $confirmedPIN)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                guard let self else { return }
//                error = nil
//            }
//            .store(in: &cancellables)
//    }
//
//    deinit { print(deinitMessage) }
//
// }
//
// extension SetPINCodeViewModel {
//    func action() {
//        switch state {
//        case .definition:
//            state = .confirmation
//
//        case .confirmation:
//            if confirmedPIN == definedPIN {
//                set(pinCode: definedPIN)
//            } else {
//                error = .notMatched
//            }
//        }
//    }
// }
//
// private extension SetPINCodeViewModel {
//    func isInvalid(pin: String) -> Bool {
//        let minLength = Constants.PINCode.minLength
//        let maxLength = Constants.PINCode.maxLength
//        return pin.isEmpty || !(minLength...maxLength).contains(pin.count)
//    }
//
//    func set(pinCode: String) {
//        Task { [weak self] in
//            guard let self else { return }
//            do {
//                try await updateSharedPreferences(\.localAuthenticationMethod, value: .pin)
//                try await updateSharedPreferences(\.pinCode, value: pinCode)
//                router.display(element: .successMessage(#localized("PIN code set"),
//                                                        config: .init(dismissBeforeShowing: true)))
//            } catch {
//                router.display(element: .displayErrorBanner(error))
//            }
//        }
//    }
// }
import Core
import DIComposition
import Entities
import FactoryKit
import Foundation
import Macro

@Observable
@MainActor
final class SetPINCodeViewModel: DeinitPrintable {
    private(set) var state: State = .definition
    var definedPIN = ""
    var confirmedPIN = ""

    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
    private let updateSharedPreferences = dependency(\UseCasesContainer.updateSharedPreferences)
    private(set) var isSaving = false
    private var failedAttempt: Attempt?

    enum State {
        case definition, confirmation
    }

    enum ValidationError: Error {
        case notMatched
    }

    private struct Attempt: Equatable {
        let defined: String
        let confirmed: String
    }

    var error: ValidationError? {
        failedAttempt == currentAttempt ? .notMatched : nil
    }

    var actionNotAllowed: Bool {
        // Always disallow when error occurs
        guard error == nil, !isSaving else { return true }
        return switch state {
        case .definition:
            isInvalid(pin: definedPIN)

        case .confirmation:
            isInvalid(pin: confirmedPIN)
        }
    }

    private var currentAttempt: Attempt {
        Attempt(defined: definedPIN, confirmed: confirmedPIN)
    }

    deinit { print(deinitMessage) }
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
                failedAttempt = currentAttempt
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
        // Deliberately unstructured and uncancelled: the two writes below must both land
        // or the app ends up with PIN auth enabled and no PIN stored.
        guard !isSaving else { return }
        isSaving = true
        Task { [weak self] in
            guard let self else { return }
            defer { isSaving = false }

            do {
                try await updateSharedPreferences(\.pinCode, value: pinCode)
                try await updateSharedPreferences(\.localAuthenticationMethod, value: .pin)
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
