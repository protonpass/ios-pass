//
// CryptoService.swift
// Proton Pass - Created on 01/10/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Entities
import Foundation
import ProtonCoreCrypto
@preconcurrency import ProtonCoreLogin

public protocol CryptoServiceProtocol: Sendable {
    func decryptShareKey(_ encryptedKey: ShareKey, userData: UserData, shareId: String) async throws -> Data
}

public final class CryptoService: CryptoServiceProtocol {
    private let remoteDatasource: any RemoteShareDatasourceProtocol
    private let localDatasource: any LocalShareDatasourceProtocol
    private let groupRepository: any GroupRepositoryProtocol
    private let logger: Logger
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let publicKeyRepository: any PublicKeyRepositoryProtocol

    public init(remoteDatasource: any RemoteShareDatasourceProtocol,
                localDatasource: any LocalShareDatasourceProtocol,
                groupRepository: any GroupRepositoryProtocol,
                logManager: any LogManagerProtocol,
                publicKeyRepository: any PublicKeyRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider) {
        self.remoteDatasource = remoteDatasource
        self.groupRepository = groupRepository
        logger = .init(manager: logManager)
        self.publicKeyRepository = publicKeyRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.localDatasource = localDatasource
    }

    public func decryptShareKey(_ encryptedKey: ShareKey,
                                userData: UserData,
                                shareId: String) async throws -> Data {
        let share = try await getShare(shareId: shareId, userData: userData)
        let keyDescription = "shareId \"\(shareId)\", keyRotation: \"\(encryptedKey.keyRotation)\""
        logger.trace("Decrypting share key \(keyDescription)")
        guard let encryptedKeyData = try encryptedKey.key.base64Decode() else {
            logger.trace("Failed to base 64 decode share key \(keyDescription)")
            throw PassError.crypto(.failedToBase64Decode)
        }

        let armoredEncryptedKeyData = try CryptoUtils.armorMessage(encryptedKeyData)

        let keys = try await getDecryptingKeys(encryptedKey: encryptedKey, userData: userData, share: share)

        let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: keys.decryptionKeys,
                                                                        value: .init(value: armoredEncryptedKeyData),
                                                                        verificationKeys: keys.verificationKeys)
        logger.trace("Decrypted share key \(keyDescription)")
        return decryptedKey.content
    }
}

private extension CryptoService {
    func getShare(shareId: String, userData: UserData) async throws -> Share {
        if let encryptedShare = try await localDatasource.getShare(userId: userData.user.ID, shareId: shareId) {
            return encryptedShare.share
        }
        return try await remoteDatasource.getShare(shareId: shareId, userId: userData.user.ID, eventToken: nil)
    }

    func getDecryptingKeys(encryptedKey: ShareKey,
                           userData: UserData,
                           share: Share) async throws -> (decryptionKeys: [DecryptionKey],
                                                          verificationKeys: [ArmoredKey]) {
        if let groupId = share.groupID {
            try await shareGroupDecryptionKeys(userData: userData, addressId: share.addressId, groupId: groupId)
        } else {
            try shareDecryptionKeys(encryptedKey: encryptedKey, userData: userData)
        }
    }

    func shareGroupDecryptionKeys(userData: UserData,
                                  addressId: String,
                                  groupId: String) async throws
        -> (decryptionKeys: [DecryptionKey], verificationKeys: [
            ArmoredKey
        ]) {
        let addressKeys = try CryptoUtils.unlockAddressKeys(addressID: addressId,
                                                            userData: userData)
        let group = try await groupRepository.getGroup(userId: userData.user.ID, groupId: groupId)
        guard let groupAddressEmail = group.address?.email else {
            logger.trace("No group address found for group with ID \(groupId)")
            throw PassError.crypto(.missingGroupAddress(groupId))
        }
        let publickey = try await publicKeyRepository.getPublicKeys(email: groupAddressEmail)
        guard !publickey.isEmpty else {
            logger.trace("No group public key found for group with ID \(groupId)")
            throw PassError.sharing(.noPublicKeyAssociatedWithEmail(groupAddressEmail))
        }
        let verificationKeys = publickey.map { ArmoredKey(value: $0.value) }

        return (addressKeys, verificationKeys)
    }

    func shareDecryptionKeys(encryptedKey: ShareKey,
                             userData: UserData) throws -> (decryptionKeys: [DecryptionKey],
                                                            verificationKeys: [ArmoredKey]) {
        guard let userKey = userData.user.keys.first(where: { $0.keyID == encryptedKey.userKeyID }),
              userKey.active == 1 else {
            throw PassError.crypto(.inactiveUserKey(userKeyId: encryptedKey.userKeyID))
        }

        let decryptionKeys = userData.user.keys.map {
            DecryptionKey(privateKey: .init(value: $0.privateKey),
                          passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
        }

        let verificationKeys = userData.user.keys.map(\.publicKey).map { ArmoredKey(value: $0) }
        return (decryptionKeys, verificationKeys)
    }
}
