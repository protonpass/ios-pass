//
// ShareKeyRepository.swift
// Proton Pass - Created on 24/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import CoreData
@preconcurrency import CryptoKit
import Entities
import ProtonCoreCrypto
@preconcurrency import ProtonCoreLogin

typealias DecryptionKey = ProtonCoreCrypto.DecryptionKey
typealias Encryptor = ProtonCoreCrypto.Encryptor

/// This repository is not offline first because without keys, the app is not functional.
public protocol ShareKeyRepositoryProtocol: Sendable {
    /// Get share keys of a share with `shareId`. Not offline first.
    func getKeys(userId: String, shareId: String) async throws -> [SymmetricallyEncryptedShareKey]

    /// Refresh share keys of a share with `shareId`
    @discardableResult
    func refreshKeys(userId: String, shareId: String) async throws -> [SymmetricallyEncryptedShareKey]

    func deleteAllCurrentUserShareKeysLocally() async throws
}

public actor ShareKeyRepository: ShareKeyRepositoryProtocol {
    private let localDatasource: any LocalShareKeyDatasourceProtocol
    private let remoteDatasource: any RemoteShareKeyDatasourceProtocol
    private let logger: Logger
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let userManager: any UserManagerProtocol

    public init(localDatasource: any LocalShareKeyDatasourceProtocol,
                remoteDatasource: any RemoteShareKeyDatasourceProtocol,
                logManager: any LogManagerProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                userManager: any UserManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        logger = .init(manager: logManager)
        self.symmetricKeyProvider = symmetricKeyProvider
        self.userManager = userManager
    }
}

public extension ShareKeyRepository {
    func getKeys(userId: String, shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        logger.trace("Getting keys for share \(shareId)")
        let keys = try await localDatasource.getKeys(shareId: shareId)
        if keys.isEmpty {
            logger.trace("No local keys for share \(shareId). Fetching from remote.")
            let keys = try await refreshKeys(userId: userId, shareId: shareId)
            logger.trace("Got \(keys.count) keys for share \(shareId) after refreshing.")
            return keys
        }

        logger.trace("Got \(keys.count) local keys for share \(shareId)")
        return keys
    }

    func refreshKeys(userId: String, shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        logger.trace("Refreshing keys for share \(shareId), user \(userId)")

        let keys = try await remoteDatasource.getKeys(userId: userId, shareId: shareId)
        logger.trace("Got \(keys.count) keys from remote for share \(shareId)")

        let encryptedKeys = try await keys.asyncCompactMap { key in
            let decryptedKey = try await decrypt(key, shareId: shareId)
            let encryptedKeyBase64 = decryptedKey.encodeBase64()
            let symmetricallyEncryptedKey = try await getSymmetricKey().encrypt(encryptedKeyBase64)
            return SymmetricallyEncryptedShareKey(encryptedKey: symmetricallyEncryptedKey,
                                                  shareId: shareId,
                                                  userId: userId,
                                                  shareKey: key)
        }

        try await localDatasource.upsertKeys(encryptedKeys)
        logger.trace("Saved \(keys.count) keys to local database for share \(shareId), user \(userId)")

        logger.trace("Refreshed keys for share \(shareId), user \(userId)")
        return encryptedKeys
    }

    func deleteAllCurrentUserShareKeysLocally() async throws {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Deleting all local share keys of user \(userId)")
        try await localDatasource.removeAllKeys(userId: userId)
        logger.trace("Deleted all local share keys")
    }
}

private extension ShareKeyRepository {
    func getSymmetricKey() async throws -> CryptoKit.SymmetricKey {
        try await symmetricKeyProvider.getSymmetricKey()
    }

    func decrypt(_ encryptedKey: ShareKey, shareId: String) async throws -> Data {
        let userData = try await userManager.getUnwrappedActiveUserData()
        let keyDescription = "shareId \"\(shareId)\", keyRotation: \"\(encryptedKey.keyRotation)\""
        logger.trace("Decrypting share key \(keyDescription)")

        guard let userKey = userData.user.keys.first(where: { $0.keyID == encryptedKey.userKeyID }),
              userKey.active == 1 else {
            throw PassError.crypto(.inactiveUserKey(userKeyId: encryptedKey.userKeyID))
        }

        guard let encryptedKeyData = try encryptedKey.key.base64Decode() else {
            logger.trace("Failed to base 64 decode share key \(keyDescription)")
            throw PassError.crypto(.failedToBase64Decode)
        }

        let armoredEncryptedKeyData = try CryptoUtils.armorMessage(encryptedKeyData)

        let decryptionKeys = userData.user.keys.map {
            DecryptionKey(privateKey: .init(value: $0.privateKey),
                          passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
        }

        let verificationKeys = userData.user.keys.map(\.publicKey).map { ArmoredKey(value: $0) }
        let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: decryptionKeys,
                                                                        value: .init(value: armoredEncryptedKeyData),
                                                                        verificationKeys: verificationKeys)

        logger.trace("Decrypted share key \(keyDescription)")
        return decryptedKey.content
    }
}
