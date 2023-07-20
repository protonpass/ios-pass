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
import ProtonCore_HumanVerification

// @MainActor
final class UserEmailViewModel: ObservableObject, Sendable {
    @Published var email = ""
    @Published private(set) var canContinue = false
    @Published var goToNextStep = false
    @Published private(set) var vaultName = ""

    private var cancellables = Set<AnyCancellable>()

    private let setShareInviteUserEmail = resolve(\UseCasesContainer.setShareInviteUserEmail)
    private let getShareInviteInfos = resolve(\UseCasesContainer.getCurrentShareInviteInformations)
    private let resetSharingInviteInfos = resolve(\UseCasesContainer.resetSharingInviteInfos)

    init() {
        setUp()
    }

    func saveEmail() {
        Task { [weak self] in
            guard let self else {
                return
            }
            await self.setShareInviteUserEmail(with: self.email)
            await MainActor.run {
                self.goToNextStep = true
            }
        }
    }

    func resetSharingInfos() {
        Task { [weak self] in
            await self?.resetSharingInviteInfos()
        }
    }
}

private extension UserEmailViewModel {
    func setUp() {
        Task { @MainActor [weak self] in
            let infos = await self?.getShareInviteInfos()
            vaultName = infos?.vault?.name ?? ""
        }

        $email
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.canContinue = newValue.isValidEmail()
            }
            .store(in: &cancellables)
    }
}
