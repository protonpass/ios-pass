//
// PromoteNewUserInvite.swift
// Proton Pass - Created on 18/10/2023.
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

import Client
import Entities
import ProtonCoreLogin

protocol PromoteNewUserInviteUseCase: Sendable {
    func execute(vault: Vault, inviteId: String, email: String) async throws
}

extension PromoteNewUserInviteUseCase {
    func callAsFunction(vault: Vault, inviteId: String, email: String) async throws {
        try await execute(vault: vault, inviteId: inviteId, email: email)
    }
}

final class PromoteNewUserInvite: PromoteNewUserInviteUseCase {
    private let publicKeyRepository: PublicKeyRepositoryProtocol
    private let passKeyManager: PassKeyManagerProtocol
    private let shareInviteRepository: ShareInviteRepositoryProtocol
    private let userDataProvider: UserDataProvider

    init(publicKeyRepository: PublicKeyRepositoryProtocol,
         passKeyManager: PassKeyManagerProtocol,
         shareInviteRepository: ShareInviteRepositoryProtocol,
         userDataProvider: UserDataProvider) {
        self.publicKeyRepository = publicKeyRepository
        self.passKeyManager = passKeyManager
        self.shareInviteRepository = shareInviteRepository
        self.userDataProvider = userDataProvider
    }

    func execute(vault: Vault, inviteId: String, email: String) async throws {
        let userData = try userDataProvider.getUnwrappedUserData()
        let publicKeys = try await publicKeyRepository.getPublicKeys(email: email)
        guard let activeKey = publicKeys.first else {
            throw PassError.sharing(.noPublicKeyAssociatedWithEmail(email))
        }
        let vaultKey = try await passKeyManager.getLatestShareKey(shareId: vault.shareId)
        let signedKey = try CryptoUtils.encryptKeyForSharing(addressId: vault.addressId,
                                                             publicReceiverKey: activeKey,
                                                             userData: userData,
                                                             vaultKey: vaultKey)
        let promoted = try await shareInviteRepository.promoteNewUserInvite(shareId: vault.shareId,
                                                                            inviteId: inviteId,
                                                                            keys: [signedKey])
        if !promoted {
            throw PassError.sharing(.failedToInvite)
        }
    }
}
