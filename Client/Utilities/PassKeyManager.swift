//
// PassKeyManager.swift
// Proton Pass - Created on 24/02/2023.
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

import Core
import CryptoKit
import ProtonCore_Crypto
import ProtonCore_Login

public protocol PassKeyManagerProtocol: AnyObject {
    /// Get share key of a given key rotation to decrypt share content
    func getShareKey(shareId: String, keyRotation: Int64) async throws -> CachableObject<DecryptedShareKey>

    /// Get share key with latest rotation
    func getLatestShareKey(shareId: String) async throws -> CachableObject<DecryptedShareKey>

    /// Get the latest key of an item to encrypt item content
    func getLatestItemKey(shareId: String, itemId: String) async throws -> CachableObject<DecryptedItemKey>
}

public struct DecryptedShareKey {
    public let shareId: String
    public let keyRotation: Int64
    public let keyData: Data
}

public struct DecryptedItemKey {
    public let shareId: String
    public let itemId: String
    public let keyRotation: Int64
    public let keyData: Data
}

public final class PassKeyManager {
    private let userData: UserData
    private let shareKeyRepository: ShareKeyRepositoryProtocol
    private let itemKeyDatasource: RemoteItemKeyDatasourceProtocol

    private var shareKeys: [ShareKey] = []
    private var decryptedShareKeys: [DecryptedShareKey] = []

    private var decryptedItemKeys: [DecryptedItemKey] = []

    private let logger: Logger

    public init(userData: UserData,
                shareKeyRepository: ShareKeyRepositoryProtocol,
                itemKeyDatasource: RemoteItemKeyDatasourceProtocol,
                logManager: LogManager) {
        self.userData = userData
        self.shareKeyRepository = shareKeyRepository
        self.itemKeyDatasource = itemKeyDatasource
        self.logger = .init(manager: logManager)
    }
}

extension PassKeyManager: PassKeyManagerProtocol {
    public func getShareKey(shareId: String,
                            keyRotation: Int64) async throws -> CachableObject<DecryptedShareKey> {
        let keyDescription = "shareId \"\(shareId)\", keyRotation: \"\(keyRotation)\""
        logger.trace("Getting share key \(keyDescription)")
        if let decryptedKey =
            decryptedShareKeys.first(where: { $0.shareId == shareId && $0.keyRotation == keyRotation }) {
            logger.trace("Found cached share key \(keyDescription)")
            return .init(isCached: true, value: decryptedKey)
        }

        logger.trace("No cached share key \(keyDescription). Getting from repository")
        let encryptedKey = try await getEncryptedShareKey(shareId: shareId, keyRotation: keyRotation)
        let decryptedKeyData = try await decrypt(encryptedKey, shareId: shareId, userData: userData)

        let decryptedKey = DecryptedShareKey(shareId: shareId,
                                             keyRotation: keyRotation,
                                             keyData: decryptedKeyData)
        decryptedShareKeys.append(decryptedKey)
        return .init(isCached: false, value: decryptedKey)
    }

    public func getLatestShareKey(shareId: String) async throws -> CachableObject<DecryptedShareKey> {
        let keyDescription = "shareId \"\(shareId)\""
        logger.trace("Getting latest share key \(keyDescription)")
        let latestShareKey = try await getEncryptedLatestShareKey(shareId: shareId)
        if let decryptedKey =
            decryptedShareKeys.first(where: { $0.shareId == shareId &&
                $0.keyRotation == latestShareKey.keyRotation }) {
            logger.trace("Found cached latest share key \(keyDescription)")
            return .init(isCached: true, value: decryptedKey)
        }

        let decryptedKeyData = try await decrypt(latestShareKey, shareId: shareId, userData: userData)
        let decryptedKey = DecryptedShareKey(shareId: shareId,
                                             keyRotation: latestShareKey.keyRotation,
                                             keyData: decryptedKeyData)
        decryptedShareKeys.append(decryptedKey)
        return .init(isCached: false, value: decryptedKey)
    }

    public func getLatestItemKey(shareId: String,
                                 itemId: String) async throws -> CachableObject<DecryptedItemKey> {
        let keyDescription = "shareId \"\(shareId)\", itemId: \"\(itemId)\""
        logger.trace("Getting latest item key \(keyDescription)")
        let latestItemKey = try await itemKeyDatasource.getLatestKey(shareId: shareId, itemId: itemId)

        if let decryptedKey =
            decryptedItemKeys.first(where: { $0.shareId == shareId &&
                $0.itemId == itemId &&
                $0.keyRotation == latestItemKey.keyRotation
            }) {
            logger.trace("Got cached latest item key \(keyDescription)")
            return .init(isCached: true, value: decryptedKey)
        }

        logger.trace("Decrypting latest item key \(keyDescription)")

        let vaultKey = try await getShareKey(shareId: shareId, keyRotation: latestItemKey.keyRotation)

        guard let encryptedItemKeyData = try latestItemKey.key.base64Decode() else {
            logger.trace("Failed to base 64 decode latest item key \(keyDescription)")
            throw PPClientError.crypto(.failedToBase64Decode)
        }

        let decryptedItemKeyData = try AES.GCM.open(encryptedItemKeyData,
                                                    key: vaultKey.value.keyData,
                                                    associatedData: .itemKey)

        logger.trace("Decrypted latest item key \(keyDescription)")
        let decryptedItemKey = DecryptedItemKey(shareId: shareId,
                                                itemId: itemId,
                                                keyRotation: latestItemKey.keyRotation,
                                                keyData: decryptedItemKeyData)
        decryptedItemKeys.append(decryptedItemKey)
        return .init(isCached: false, value: decryptedItemKey)
    }
}

private extension PassKeyManager {
    func getEncryptedShareKey(shareId: String, keyRotation: Int64) async throws -> ShareKey {
        let shareKeys = try await shareKeyRepository.getKeys(shareId: shareId)

        if let matchedKey = shareKeys.first(where: { $0.keyRotation == keyRotation }) {
            return matchedKey
        }

        let refreshedShareKeys = try await shareKeyRepository.refreshKeys(shareId: shareId)

        guard let matchedKey = refreshedShareKeys.first(where: { $0.keyRotation == keyRotation }) else {
            throw PPClientError.crypto(.missingKeys)
        }
        return matchedKey
    }

    func getEncryptedLatestShareKey(shareId: String) async throws -> ShareKey {
        let refreshedShareKeys = try await shareKeyRepository.refreshKeys(shareId: shareId)
        return try refreshedShareKeys.latestKey()
    }

    func decrypt(_ encryptedKey: ShareKey, shareId: String, userData: UserData) async throws -> Data {
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
