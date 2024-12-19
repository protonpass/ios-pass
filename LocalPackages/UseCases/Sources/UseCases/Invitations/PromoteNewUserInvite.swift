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

public protocol PromoteNewUserInviteUseCase: Sendable {
    func execute(share: Share,
                 inviteId: String,
                 email: String,
                 itemId: String?) async throws
}

public extension PromoteNewUserInviteUseCase {
    func callAsFunction(share: Share,
                        inviteId: String,
                        email: String,
                        itemId: String? = nil) async throws {
        try await execute(share: share, inviteId: inviteId, email: email, itemId: itemId)
    }
}

public final class PromoteNewUserInvite: PromoteNewUserInviteUseCase {
    private let publicKeyRepository: any PublicKeyRepositoryProtocol
    private let passKeyManager: any PassKeyManagerProtocol
    private let shareInviteRepository: any ShareInviteRepositoryProtocol
    private let userManager: any UserManagerProtocol

    public init(publicKeyRepository: any PublicKeyRepositoryProtocol,
                passKeyManager: any PassKeyManagerProtocol,
                shareInviteRepository: any ShareInviteRepositoryProtocol,
                userManager: any UserManagerProtocol) {
        self.publicKeyRepository = publicKeyRepository
        self.passKeyManager = passKeyManager
        self.shareInviteRepository = shareInviteRepository
        self.userManager = userManager
    }

    public func execute(share: Share,
                        inviteId: String,
                        email: String,
                        itemId: String?) async throws {
        let userData = try await userManager.getUnwrappedActiveUserData()
        let publicKeys = try await publicKeyRepository.getPublicKeys(email: email)
        guard let activeKey = publicKeys.first else {
            throw PassError.sharing(.noPublicKeyAssociatedWithEmail(email))
        }

        let key: any ShareKeyProtocol = if share.isVaultRepresentation {
            try await passKeyManager.getLatestShareKey(userId: userData.user.ID,
                                                       shareId: share.id)
        } else if let itemId {
            try await passKeyManager.getLatestItemKey(userId: userData.user.ID,
                                                      shareId: share.id,
                                                      itemId: itemId)
        } else {
            throw PassError.sharing(.failedEncryptionKeysFetching)
        }

        let signedKey = try CryptoUtils.encryptKeyForSharing(addressId: share.addressId,
                                                             publicReceiverKey: activeKey,
                                                             userData: userData,
                                                             key: key)
        let promoted = try await shareInviteRepository.promoteNewUserInvite(shareId: share.id,
                                                                            inviteId: inviteId,
                                                                            keys: [signedKey])
        if !promoted {
            throw PassError.sharing(.failedToInvite)
        }
    }
}
