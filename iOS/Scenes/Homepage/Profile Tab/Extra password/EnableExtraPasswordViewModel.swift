//
// EnableExtraPasswordViewModel.swift
// Proton Pass - Created on 30/05/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import Foundation
import Macro

enum EnableExtraPasswordViewState {
    case defining, repeating

    var navigationTitle: String {
        switch self {
        case .defining:
            #localized("Set extra password")
        case .repeating:
            #localized("Repeat extra password")
        }
    }

    var placeholder: String {
        switch self {
        case .defining:
            #localized("Extra password")
        case .repeating:
            #localized("Confirm extra password")
        }
    }
}

@MainActor
final class EnableExtraPasswordViewModel: ObservableObject {
    @Published private(set) var canContinue = false
    @Published private(set) var canSetExtraPassword = false
    @Published private(set) var protonPasswordVerificationError: (any Error)?
    @Published private(set) var enableExtraPasswordError: (any Error)?
    @Published private(set) var state: EnableExtraPasswordViewState = .defining
    @Published private(set) var loading = false
    @Published var showLogOutAlert = false
    @Published var showWrongProtonPasswordAlert = false
    @Published var showProtonPasswordConfirmationAlert = true
    @Published var extraPasswordEnabled = false
    @Published var protonPassword = ""
    @Published var extraPassword = ""

    private var definedExtraPassword = ""
    private var cancellables = Set<AnyCancellable>()

    private let doVerifyProtonPassword = resolve(\UseCasesContainer.verifyProtonPassword)
    private let enableExtraPassword = resolve(\UseCasesContainer.enableExtraPassword)

    init() {
        $extraPassword
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] password in
                guard let self else { return }
                switch state {
                case .defining:
                    canContinue = password.count >= Constants.ExtraPassword.minLength
                case .repeating:
                    canContinue = password.count >= Constants.ExtraPassword.minLength &&
                        password == definedExtraPassword
                }
            }
            .store(in: &cancellables)
    }
}

extension EnableExtraPasswordViewModel {
    func verifyProtonPassword() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                loading = true
                if try await doVerifyProtonPassword(protonPassword) {
                    canSetExtraPassword = true
                } else {
                    showWrongProtonPasswordAlert = true
                }
            } catch {
                protonPasswordVerificationError = error
            }
        }
    }

    func retryVerifyingProtonPassword() {
        protonPassword = ""
        showProtonPasswordConfirmationAlert = true
    }

    func `continue`() {
        switch state {
        case .defining:
            definedExtraPassword = extraPassword
            extraPassword = ""
            state = .repeating
        case .repeating:
            showLogOutAlert = true
        }
    }

    func proceedSetUp() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                loading = true
                try await enableExtraPassword(definedExtraPassword)
                extraPasswordEnabled = true
            } catch {
                enableExtraPasswordError = error
            }
        }
    }
}
