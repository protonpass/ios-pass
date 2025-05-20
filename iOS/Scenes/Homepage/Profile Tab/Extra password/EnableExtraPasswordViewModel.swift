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

import Core
import FactoryKit
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
    @Published private(set) var canSetExtraPassword = false
    @Published private(set) var protonPasswordVerificationError: (any Error)?
    @Published private(set) var enableExtraPasswordError: (any Error)?
    @Published private(set) var state: EnableExtraPasswordViewState = .defining
    @Published private(set) var loading = false
    @Published var showLogOutAlert = false
    @Published var showWrongProtonPasswordAlert = false
    @Published var showProtonPasswordConfirmationAlert = true
    @Published var extraPasswordEnabled = false
    @Published var failedToVerifyProtonPassword = false
    @Published var protonPassword = ""
    @Published var extraPassword = ""

    private var definedExtraPassword = ""
    private var protonPasswordFailedVerificationCount = 0

    private let doVerifyProtonPassword = resolve(\UseCasesContainer.verifyProtonPassword)
    private let enableExtraPassword = resolve(\UseCasesContainer.enableExtraPassword)
    private let updateUserPreferences = resolve(\SharedUseCasesContainer.updateUserPreferences)
    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)
    private let userManager = resolve(\SharedServiceContainer.userManager)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init() {
        Task { [weak self] in
            guard let self else { return }
            protonPasswordFailedVerificationCount =
                preferencesManager.userPreferences.unwrapped().protonPasswordFailedVerificationCount
        }
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
                    try await updateUserPreferences(\.protonPasswordFailedVerificationCount,
                                                    value: 0)
                    canSetExtraPassword = true
                } else {
                    protonPasswordFailedVerificationCount += 1
                    try await updateUserPreferences(\.protonPasswordFailedVerificationCount,
                                                    value: protonPasswordFailedVerificationCount)
                    if protonPasswordFailedVerificationCount < 5 {
                        showWrongProtonPasswordAlert = true
                    } else {
                        failedToVerifyProtonPassword = true
                    }
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
            let minLength = Constants.ExtraPassword.minLength
            guard extraPassword.count >= minLength else {
                let errorMessage = #localized("Extra password must have at least %lld characters", minLength)
                router.display(element: .errorMessage(errorMessage))
                return
            }
            definedExtraPassword = extraPassword
            extraPassword = ""
            state = .repeating

        case .repeating:
            guard extraPassword == definedExtraPassword else {
                let errorMessage = #localized("Passwords do not match")
                router.display(element: .errorMessage(errorMessage))
                return
            }
            showLogOutAlert = true
        }
    }

    func proceedSetUp() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await enableExtraPassword(userId: userId,
                                              password: definedExtraPassword)
                try await updateUserPreferences(\.extraPasswordEnabled, value: true)
                extraPasswordEnabled = true
            } catch {
                enableExtraPasswordError = error
            }
        }
    }
}
