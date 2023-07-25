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

protocol SendShareInviteUseCase: Sendable {
    func execute(with infos: SharingInfos, and targetType: TargetType) async throws -> Bool
}

extension SendShareInviteUseCase {
    func callAsFunction(with infos: SharingInfos,
                        and targetType: TargetType = .vault) async throws -> Bool {
        try await execute(with: infos, and: targetType)
    }
}

final class SendShareInvite: @unchecked Sendable, SendShareInviteUseCase {
    private let publicKeyRepository: PublicKeyRepositoryProtocol
    private let passKeyManager: PassKeyManagerProtocol
    private let shareInviteRepository: ShareInviteRepositoryProtocol
    private let userData: UserData

    init(publicKeyRepository: PublicKeyRepositoryProtocol,
         passKeyManager: PassKeyManagerProtocol,
         shareInviteRepository: ShareInviteRepositoryProtocol,
         userData: UserData) {
        self.publicKeyRepository = publicKeyRepository
        self.passKeyManager = passKeyManager
        self.shareInviteRepository = shareInviteRepository
        self.userData = userData
    }

    func execute(with infos: SharingInfos, and targetType: TargetType = .vault) async throws -> Bool {
        guard let vault = infos.vault,
              let email = infos.email,
              let role = infos.role else {
            throw SharingErrors.incompleteInformation
        }
        guard let receivingKeys = try? await publicKeyRepository.getPublicKeys(email: email),
              let sharedKeys = try? await passKeyManager.getLatestShareKey(shareId: vault.shareId) else {
            throw SharingErrors.failedEncryptionKeysFetching
        }

        let signedKeys = try encryptKeys(addressId: vault.addressId,
                                         receivingKey: receivingKeys.first?.value ?? "",
                                         userData: userData,
                                         vaultKey: sharedKeys)

        return try await shareInviteRepository.sendInvite(shareId: vault.shareId,
                                                          keys: [signedKeys],
                                                          email: email,
                                                          targetType: targetType,
                                                          shareRole: role)
    }
}

private extension SendShareInvite {
    func encryptKeys(addressId: String,
                     receivingKey: String,
                     userData: UserData,
                     vaultKey: DecryptedShareKey) throws -> ItemKey {
        guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: addressId,
                                                                 userData: userData).first else {
            throw PPClientError.crypto(.addressNotFound(addressID: addressId))
        }

        let publicKey = ArmoredKey(value: receivingKey)
        let signerKey = SigningKey(privateKey: addressKey.privateKey,
                                   passphrase: addressKey.passphrase)

        let encryptedVaultKeyString = try Encryptor.encrypt(publicKey: publicKey,
                                                            clearData: vaultKey.keyData,
                                                            signerKey: signerKey)
            .unArmor().value.base64EncodedString()

        return ItemKey(key: encryptedVaultKeyString, keyRotation: vaultKey.keyRotation)
    }
}
