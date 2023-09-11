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

import Combine
import Factory
import Foundation
import ProtonCoreHumanVerification

@MainActor
final class UserEmailViewModel: ObservableObject, Sendable {
    @Published var email = ""
    @Published private(set) var canContinue = false
    @Published var goToNextStep = false
    @Published private(set) var vaultName = ""
    @Published private(set) var error: String?
    @Published private(set) var isChecking = false

    private var cancellables = Set<AnyCancellable>()
    private let setShareInviteUserEmailAndKeys = resolve(\UseCasesContainer.setShareInviteUserEmailAndKeys)
    private let getShareInviteInfos = resolve(\UseCasesContainer.getCurrentShareInviteInformations)
    private let getEmailPublicKey = resolve(\UseCasesContainer.getEmailPublicKey)
    private var checkTask: Task<Void, Never>?

    init() {
        setUp()
    }

    func saveEmail() {
        checkTask?.cancel()
        checkTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                self.isChecking = false
                self.checkTask?.cancel()
                self.checkTask = nil
            }
            do {
                if Task.isCancelled {
                    return
                }
                self.isChecking = true
                let receiverPublicKeys = try await self.getEmailPublicKey(with: email)
                self.setShareInviteUserEmailAndKeys(with: email, and: receiverPublicKeys)
                self.goToNextStep = true
            } catch {
                self.error = "You cannot share \(vaultName) vault with this email"
            }
        }
    }
}

private extension UserEmailViewModel {
    func setUp() {
        vaultName = getShareInviteInfos().vault?.name ?? ""
        assert(getShareInviteInfos().vault != nil, "Vault is not set")

        $email
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                if self?.error != nil {
                    self?.error = nil
                }
                self?.canContinue = newValue.isValidEmail()
            }
            .store(in: &cancellables)
    }
}
