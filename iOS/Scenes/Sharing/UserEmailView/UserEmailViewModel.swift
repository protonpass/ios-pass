//
//
// UserEmailViewModel.swift
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
//

import Client
import Combine
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreHumanVerification

@MainActor
final class UserEmailViewModel: ObservableObject, Sendable {
    @Published var email = ""
    @Published private(set) var canContinue = false
    @Published var goToNextStep = false
    @Published private(set) var vault: SharingVaultData?
    @Published private(set) var error: String?
    @Published private(set) var isChecking = false

    private var cancellables = Set<AnyCancellable>()
    private let shareInviteService = resolve(\ServiceContainer.shareInviteService)
    private let setShareInviteUserEmailAndKeys = resolve(\UseCasesContainer.setShareInviteUserEmailAndKeys)
    private let getEmailPublicKey = resolve(\UseCasesContainer.getEmailPublicKey)
    private let getFeatureFlagStatus = resolve(\SharedUseCasesContainer.getFeatureFlagStatus)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init() {
        setUp()
    }

    func saveEmail() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                isChecking = false
            }
            do {
                isChecking = true
                let receiverPublicKeys = try await getEmailPublicKey(with: email)
                setShareInviteUserEmailAndKeys(with: email, and: receiverPublicKeys)
                goToNextStep = true
            } catch {
                if let passError = error as? PassError,
                   case let .sharing(reason) = passError,
                   reason == .notProtonAddress,
                   await getFeatureFlagStatus(with: FeatureFlagType.passSharingNewUsers) {
                    setShareInviteUserEmailAndKeys(with: email, and: nil)
                    goToNextStep = true
                } else {
                    canContinue = false
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func customizeVault() {
        if case let .new(vault, itemContent) = vault {
            router.present(for: .customizeNewVault(vault, itemContent))
        }
    }

    func resetShareInviteInformation() {
        shareInviteService.resetShareInviteInformations()
    }
}

private extension UserEmailViewModel {
    func setUp() {
        $email
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                error = nil
                canContinue = newValue.isValidEmail()
            }
            .store(in: &cancellables)

        shareInviteService
            .currentSelectedVault
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentVault in
                guard let self else { return }
                vault = currentVault
            }
            .store(in: &cancellables)
    }
}
