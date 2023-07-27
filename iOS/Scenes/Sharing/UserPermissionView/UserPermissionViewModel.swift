//
//
// UserPermissionViewModel.swift
// Proton Pass - Created on 20/07/2023.
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

import Entities
import Factory
import Foundation

@MainActor
final class UserPermissionViewModel: ObservableObject, Sendable {
    @Published private(set) var selectedUserRole: ShareRole = .read
    @Published private(set) var vaultName = ""
    @Published private(set) var email = ""
    @Published private(set) var canContinue = false
    @Published var goToNextStep = false

    private let setShareInviteRole = resolve(\UseCasesContainer.setShareInviteRole)
    private let getShareInviteInfos = resolve(\UseCasesContainer.getCurrentShareInviteInformations)

    init() {
        setUp()
    }

    func select(role: ShareRole) {
        setShareInviteRole(with: role)
        selectedUserRole = role
    }
}

private extension UserPermissionViewModel {
    func setUp() {
        let infos = getShareInviteInfos()
        selectedUserRole = infos.role ?? .read
        setShareInviteRole(with: selectedUserRole)
        canContinue = true
        vaultName = infos.vault?.name ?? ""
        email = infos.email ?? ""
    }
}
