//
//
// SendShareInvite.swift
// Proton Pass - Created on 21/07/2023.
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
import CryptoKit
import Entities
import ProtonCore_Crypto
import ProtonCore_Login

protocol SendVaultShareInviteUseCase: Sendable {
    func execute(with infos: SharingInfos) async throws -> Bool
}

extension SendVaultShareInviteUseCase {
    func callAsFunction(with infos: SharingInfos) async throws -> Bool {
        try await execute(with: infos)
    }
}

final class SendVaultShareInvite: @unchecked Sendable, SendVaultShareInviteUseCase {
    private let passKeyManager: PassKeyManagerProtocol
    private let shareInviteRepository: ShareInviteRepositoryProtocol
    private let userData: UserData
    private let syncEventLoop: SyncEventLoopProtocol

    init(passKeyManager: PassKeyManagerProtocol,
         shareInviteRepository: ShareInviteRepositoryProtocol,
         userData: UserData,
         syncEventLoop: SyncEventLoopProtocol) {
        self.passKeyManager = passKeyManager
        self.shareInviteRepository = shareInviteRepository
        self.userData = userData
        self.syncEventLoop = syncEventLoop
    }

    func execute(with infos: SharingInfos) async throws -> Bool {
        guard let vault = infos.vault,
              let email = infos.email,
              let role = infos.role,
              let publicReceiverKeys = infos.receiverPublicKeys else {
            throw SharingError.incompleteInformation
        }

        let sharedKey = try await passKeyManager.getLatestShareKey(shareId: vault.shareId)

        guard let publicReceiverKey = publicReceiverKeys.first?.value else {
            throw SharingError.failedEncryptionKeysFetching
        }

        let signedKeys = try encryptKeys(addressId: vault.addressId,
                                         publicReceiverKey: publicReceiverKey,
                                         userData: userData,
                                         vaultKey: sharedKey)

        let result = try await shareInviteRepository.sendInvite(shareId: vault.shareId,
                                                                keys: [signedKeys],
                                                                email: email,
                                                                targetType: .vault,
                                                                shareRole: role)
        syncEventLoop.forceSync()

        return result
    }
}

private extension SendVaultShareInvite {
    func encryptKeys(addressId: String,
                     publicReceiverKey: String,
                     userData: UserData,
                     vaultKey: DecryptedShareKey) throws -> ItemKey {
        guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: addressId,
                                                                 userData: userData).first else {
            throw PPClientError.crypto(.addressNotFound(addressID: addressId))
        }

        let publicKey = ArmoredKey(value: publicReceiverKey)
        let signerKey = SigningKey(privateKey: addressKey.privateKey,
                                   passphrase: addressKey.passphrase)

        let encryptedVaultKeyString = try Encryptor.encrypt(publicKey: publicKey,
                                                            clearData: vaultKey.keyData,
                                                            signerKey: signerKey)
            .unArmor().value.base64EncodedString()

        return ItemKey(key: encryptedVaultKeyString, keyRotation: vaultKey.keyRotation)
    }
}
