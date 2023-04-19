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
import CryptoKit
import ProtonCore_Crypto
import ProtonCore_Login
import ProtonCore_Services

typealias DecryptionKey = ProtonCore_Crypto.DecryptionKey
typealias Encryptor = ProtonCore_Crypto.Encryptor

/// This repository is not offline first because without keys, the app is not functional.
public protocol ShareKeyRepositoryProtocol {
    var localShareKeyDatasource: LocalShareKeyDatasourceProtocol { get }
    var remoteShareKeyDatasource: RemoteShareKeyDatasourceProtocol { get }
    var logger: Logger { get }
    var symmetricKey: CryptoKit.SymmetricKey { get }
    var userData: UserData { get }

    /// Get share keys of a share with `shareId`. Not offline first.
    func getKeys(shareId: String) async throws -> [SymmetricallyEncryptedShareKey]

    /// Refresh share keys of a share with `shareId`
    @discardableResult
    func refreshKeys(shareId: String) async throws -> [SymmetricallyEncryptedShareKey]
}

public extension ShareKeyRepositoryProtocol {
    func getKeys(shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        logger.trace("Getting keys for share \(shareId)")
        let keys = try await localShareKeyDatasource.getKeys(shareId: shareId)
        if keys.isEmpty {
            logger.trace("No local keys for share \(shareId). Fetching from remote.")
            let keys = try await refreshKeys(shareId: shareId)
            logger.trace("Got \(keys.count) keys for share \(shareId) after refreshing.")
            return keys
        }

        logger.trace("Got \(keys.count) local keys for share \(shareId)")
        return keys
    }

    func refreshKeys(shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        logger.trace("Refreshing keys for share \(shareId)")
        let keys = try await remoteShareKeyDatasource.getKeys(shareId: shareId)
        logger.trace("Got \(keys.count) keys from remote for share \(shareId)")

        let encryptedKeys = try keys.map { key in
            let decryptedKey = try decrypt(key, shareId: shareId, userData: userData)
            let dencryptedKeyBase64 = decryptedKey.encodeBase64()
            let symmetricallyEncryptedKey = try symmetricKey.encrypt(dencryptedKeyBase64)
            return SymmetricallyEncryptedShareKey(encryptedKey: symmetricallyEncryptedKey,
                                                  shareId: shareId,
                                                  shareKey: key)
        }

        try await localShareKeyDatasource.upsertKeys(encryptedKeys)
        logger.trace("Saved \(keys.count) keys to local database for share \(shareId)")

        logger.trace("Refreshed keys for share \(shareId)")
        return encryptedKeys
    }
}

private extension ShareKeyRepositoryProtocol {
    func decrypt(_ encryptedKey: ShareKey, shareId: String, userData: UserData) throws -> Data {
        let keyDescription = "shareId \"\(shareId)\", keyRotation: \"\(encryptedKey.keyRotation)\""
        logger.trace("Decrypting share key \(keyDescription)")
        guard let encryptedKeyData = try encryptedKey.key.base64Decode() else {
            logger.trace("Failed to base 64 decode share key \(keyDescription)")
            throw PPClientError.crypto(.failedToBase64Decode)
        }

        let armoredEncryptedKeyData = try CryptoUtils.armorMessage(encryptedKeyData)

        let decryptionKeys = userData.user.keys.map {
            DecryptionKey(privateKey: .init(value: $0.privateKey),
                          passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
        }

        let verificationKeys = userData.user.keys.map { $0.publicKey }.map { ArmoredKey(value: $0) }
        let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(
            decryptionKeys: decryptionKeys,
            value: .init(value: armoredEncryptedKeyData),
            verificationKeys: verificationKeys)

        logger.trace("Decrypted share key \(keyDescription)")
        return decryptedKey.content
    }
}

public final class ShareKeyRepository: ShareKeyRepositoryProtocol {
    public let localShareKeyDatasource: LocalShareKeyDatasourceProtocol
    public let remoteShareKeyDatasource: RemoteShareKeyDatasourceProtocol
    public let logger: Logger
    public let symmetricKey: CryptoKit.SymmetricKey
    public var userData: UserData

    public init(localShareKeyDatasource: LocalShareKeyDatasourceProtocol,
                remoteShareKeyDatasource: RemoteShareKeyDatasourceProtocol,
                logManager: LogManager,
                symmetricKey: CryptoKit.SymmetricKey,
                userData: UserData) {
        self.localShareKeyDatasource = localShareKeyDatasource
        self.remoteShareKeyDatasource = remoteShareKeyDatasource
        self.logger = .init(manager: logManager)
        self.symmetricKey = symmetricKey
        self.userData = userData
    }

    public init(container: NSPersistentContainer,
                apiService: APIService,
                logManager: LogManager,
                symmetricKey: CryptoKit.SymmetricKey,
                userData: UserData) {
        self.localShareKeyDatasource = LocalShareKeyDatasource(container: container)
        self.remoteShareKeyDatasource = RemoteShareKeyDatasource(apiService: apiService)
        self.logger = .init(manager: logManager)
        self.symmetricKey = symmetricKey
        self.userData = userData
    }
}
