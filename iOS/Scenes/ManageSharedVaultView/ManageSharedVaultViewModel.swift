//
//
// ManageSharedVaultViewModel.swift
// Proton Pass - Created on 02/08/2023.
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
import Entities
import Factory
import Foundation
import ProtonCore_Networking

final class ManageSharedVaultViewModel: ObservableObject, Sendable {
    @Published private(set) var vault: Vault
    @Published private(set) var itemsNumber: Int?
    @Published private(set) var users: [UserShareInfos] = []
    @Published private(set) var loading = false

    private let getVaultItemCount = resolve(\UseCasesContainer.getVaultItemCount)
    private let getUsersLinkedToShare: GetUsersLinkedToShareUseCase = resolve(\UseCasesContainer
        .getUsersLinkedToShare)
    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)

    init(vault: Vault) {
        self.vault = vault
        setUp()
    }

    func isLast(info: UserShareInfos) -> Bool {
        users.last == info
    }
}

private extension ManageSharedVaultViewModel {
    func setUp() {
        setShareInviteVault(with: vault)

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.loading = true
            defer { self.loading = false }
            do {
                self.itemsNumber = self.getVaultItemCount(for: self.vault)
                let user = try await self.getUsersLinkedToShare(with: vault.shareId)
                print(user)
                self.users = user
            } catch {
                print(error)
            }
        }
    }
}
