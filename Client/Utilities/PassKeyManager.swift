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
import ProtonCore_Login

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

public protocol PassKeyManagerProtocol: AnyObject {
    var itemKeyDatasource: RemoteItemKeyDatasourceProtocol { get }
    var shareKeyRepository: ShareKeyRepositoryProtocol { get }
    var logger: Logger { get }
    var symmetricKey: SymmetricKey { get }

    /// Get share key of a given key rotation to decrypt share content
    func getShareKey(shareId: String, keyRotation: Int64) async throws -> DecryptedShareKey

    /// Get share key with latest rotation
    func getLatestShareKey(shareId: String) async throws -> DecryptedShareKey

    /// Get the latest key of an item to encrypt item content
    func getLatestItemKey(shareId: String, itemId: String) async throws -> DecryptedItemKey
}

public extension PassKeyManagerProtocol {
    func getShareKey(shareId: String, keyRotation: Int64) async throws -> DecryptedShareKey {
        let allEncryptedShareKeys = try await shareKeyRepository.getKeys(shareId: shareId)
        guard let encryptedShareKey = allEncryptedShareKeys.first(where: { $0.shareId == shareId }) else {
            throw PPClientError.keysNotFound(shareID: shareId)
        }
        return try decrypt(encryptedShareKey)
    }

    func getLatestShareKey(shareId: String) async throws -> DecryptedShareKey {
        let allEncryptedShareKeys = try await shareKeyRepository.getKeys(shareId: shareId)
        let latestShareKey = try allEncryptedShareKeys.latestKey()
        return try decrypt(latestShareKey)
    }

    func getLatestItemKey(shareId: String, itemId: String) async throws -> DecryptedItemKey {
        let keyDescription = "shareId \"\(shareId)\", itemId: \"\(itemId)\""
        logger.trace("Getting latest item key \(keyDescription)")
        let latestItemKey = try await itemKeyDatasource.getLatestKey(shareId: shareId, itemId: itemId)

        let decryptedKey = try await getShareKey(shareId: shareId,
                                                 keyRotation: latestItemKey.keyRotation)

        logger.trace("Decrypting latest item key \(keyDescription)")

        let vaultKey = try await getShareKey(shareId: shareId, keyRotation: latestItemKey.keyRotation)

        guard let encryptedItemKeyData = try latestItemKey.key.base64Decode() else {
            logger.trace("Failed to base 64 decode latest item key \(keyDescription)")
            throw PPClientError.crypto(.failedToBase64Decode)
        }

        let decryptedItemKeyData = try AES.GCM.open(encryptedItemKeyData,
                                                    key: vaultKey.keyData,
                                                    associatedData: .itemKey)

        logger.trace("Decrypted latest item key \(keyDescription)")
        return .init(shareId: shareId,
                     itemId: itemId,
                     keyRotation: latestItemKey.keyRotation,
                     keyData: decryptedItemKeyData)
    }
}

private extension PassKeyManagerProtocol {
    func decrypt(_ encryptedShareKey: SymmetricallyEncryptedShareKey) throws -> DecryptedShareKey {
        let decryptedKey = try symmetricKey.decrypt(encryptedShareKey.encryptedKey)
        guard let decryptedKeyData = try decryptedKey.base64Decode() else {
            throw PPClientError.crypto(.failedToBase64Decode)
        }
        return .init(shareId: encryptedShareKey.shareId,
                     keyRotation: encryptedShareKey.shareKey.keyRotation,
                     keyData: decryptedKeyData)
    }
}

public final class PassKeyManager: PassKeyManagerProtocol {
    public let shareKeyRepository: ShareKeyRepositoryProtocol
    public let itemKeyDatasource: RemoteItemKeyDatasourceProtocol
    public let logger: Logger
    public let symmetricKey: SymmetricKey

    public init(shareKeyRepository: ShareKeyRepositoryProtocol,
                itemKeyDatasource: RemoteItemKeyDatasourceProtocol,
                logManager: LogManager,
                symmetricKey: SymmetricKey) {
        self.shareKeyRepository = shareKeyRepository
        self.itemKeyDatasource = itemKeyDatasource
        self.logger = .init(manager: logManager)
        self.symmetricKey = symmetricKey
    }
}
