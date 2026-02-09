// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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
import Collections
import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreLogin

public final class PassKeyManagerProtocolMock: @unchecked Sendable, PassKeyManagerProtocol {

    public init() {}

    // MARK: - getShareKey
    public var getShareKeyUserIdShareIdKeyRotationThrowableError1: Error?
    public var closureGetShareKey: () -> () = {}
    public var invokedGetShareKeyfunction = false
    public var invokedGetShareKeyCount = 0
    public var invokedGetShareKeyParameters: (userId: String, shareId: String, keyRotation: Int64)?
    public var invokedGetShareKeyParametersList = [(userId: String, shareId: String, keyRotation: Int64)]()
    public nonisolated(unsafe) var stubbedGetShareKeyResult: (any CryptographicKeyProtocol)!

    public func getShareKey(userId: String, shareId: String, keyRotation: Int64) async throws -> any CryptographicKeyProtocol {
        invokedGetShareKeyfunction = true
        invokedGetShareKeyCount += 1
        invokedGetShareKeyParameters = (userId, shareId, keyRotation)
        if let error = getShareKeyUserIdShareIdKeyRotationThrowableError1 {
            throw error
        }
        closureGetShareKey()
        return stubbedGetShareKeyResult
    }
    // MARK: - getLatestShareKey
    public var getLatestShareKeyUserIdShareIdThrowableError2: Error?
    public var closureGetLatestShareKey: () -> () = {}
    public var invokedGetLatestShareKeyfunction = false
    public var invokedGetLatestShareKeyCount = 0
    public var invokedGetLatestShareKeyParameters: (userId: String, shareId: String)?
    public var invokedGetLatestShareKeyParametersList = [(userId: String, shareId: String)]()
    public nonisolated(unsafe) var stubbedGetLatestShareKeyResult: (any CryptographicKeyProtocol)!

    public func getLatestShareKey(userId: String, shareId: String) async throws -> any CryptographicKeyProtocol {
        invokedGetLatestShareKeyfunction = true
        invokedGetLatestShareKeyCount += 1
        invokedGetLatestShareKeyParameters = (userId, shareId)
        if let error = getLatestShareKeyUserIdShareIdThrowableError2 {
            throw error
        }
        closureGetLatestShareKey()
        return stubbedGetLatestShareKeyResult
    }
    // MARK: - getShareKeys
    public var getShareKeysUserIdShareItemThrowableError3: Error?
    public var closureGetShareKeys: () -> () = {}
    public var invokedGetShareKeysfunction = false
    public var invokedGetShareKeysCount = 0
    public var invokedGetShareKeysParameters: (userId: String, share: Share, item: any FullItemIdentifiable)?
    public var invokedGetShareKeysParametersList = [(userId: String, share: Share, item: any FullItemIdentifiable)]()
    public nonisolated(unsafe) var stubbedGetShareKeysResult: ([any CryptographicKeyProtocol])!

    public func getShareKeys(userId: String, share: Share, item: any FullItemIdentifiable) async throws -> [any CryptographicKeyProtocol] {
        invokedGetShareKeysfunction = true
        invokedGetShareKeysCount += 1
        invokedGetShareKeysParameters = (userId, share, item)
        if let error = getShareKeysUserIdShareItemThrowableError3 {
            throw error
        }
        closureGetShareKeys()
        return stubbedGetShareKeysResult
    }
    // MARK: - getLatestItemKey
    public var getLatestItemKeyUserIdShareIdParentIdItemIdThrowableError4: Error?
    public var closureGetLatestItemKey: () -> () = {}
    public var invokedGetLatestItemKeyfunction = false
    public var invokedGetLatestItemKeyCount = 0
    public var invokedGetLatestItemKeyParameters: (userId: String, shareId: String, parentId: String, itemId: String)?
    public var invokedGetLatestItemKeyParametersList = [(userId: String, shareId: String, parentId: String, itemId: String)]()
    public nonisolated(unsafe) var stubbedGetLatestItemKeyResult: (any CryptographicKeyProtocol)!

    public func getLatestItemKey(userId: String, shareId: String, parentId: String, itemId: String) async throws -> any CryptographicKeyProtocol {
        invokedGetLatestItemKeyfunction = true
        invokedGetLatestItemKeyCount += 1
        invokedGetLatestItemKeyParameters = (userId, shareId, parentId, itemId)
        if let error = getLatestItemKeyUserIdShareIdParentIdItemIdThrowableError4 {
            throw error
        }
        closureGetLatestItemKey()
        return stubbedGetLatestItemKeyResult
    }
    // MARK: - getItemKeys
    public var getItemKeysUserIdShareIdParentIdItemIdThrowableError5: Error?
    public var closureGetItemKeys: () -> () = {}
    public var invokedGetItemKeysfunction = false
    public var invokedGetItemKeysCount = 0
    public var invokedGetItemKeysParameters: (userId: String, shareId: String, parentId: String, itemId: String)?
    public var invokedGetItemKeysParametersList = [(userId: String, shareId: String, parentId: String, itemId: String)]()
    public nonisolated(unsafe) var stubbedGetItemKeysResult: ([any CryptographicKeyProtocol])!

    public func getItemKeys(userId: String, shareId: String, parentId: String, itemId: String) async throws -> [any CryptographicKeyProtocol] {
        invokedGetItemKeysfunction = true
        invokedGetItemKeysCount += 1
        invokedGetItemKeysParameters = (userId, shareId, parentId, itemId)
        if let error = getItemKeysUserIdShareIdParentIdItemIdThrowableError5 {
            throw error
        }
        closureGetItemKeys()
        return stubbedGetItemKeysResult
    }
    // MARK: - getItemKey
    public var getItemKeyUserIdShareIdParentIdItemIdKeyRotationThrowableError6: Error?
    public var closureGetItemKey: () -> () = {}
    public var invokedGetItemKeyfunction = false
    public var invokedGetItemKeyCount = 0
    public var invokedGetItemKeyParameters: (userId: String, shareId: String, parentId: String, itemId: String, keyRotation: Int64)?
    public var invokedGetItemKeyParametersList = [(userId: String, shareId: String, parentId: String, itemId: String, keyRotation: Int64)]()
    public nonisolated(unsafe) var stubbedGetItemKeyResult: (any CryptographicKeyProtocol)!

    public func getItemKey(userId: String, shareId: String, parentId: String, itemId: String, keyRotation: Int64) async throws -> any CryptographicKeyProtocol {
        invokedGetItemKeyfunction = true
        invokedGetItemKeyCount += 1
        invokedGetItemKeyParameters = (userId, shareId, parentId, itemId, keyRotation)
        if let error = getItemKeyUserIdShareIdParentIdItemIdKeyRotationThrowableError6 {
            throw error
        }
        closureGetItemKey()
        return stubbedGetItemKeyResult
    }
    // MARK: - decryptAndStoreFolderKeys
    public var decryptAndStoreFolderKeysShareIdFoldersThrowableError7: Error?
    public var closureDecryptAndStoreFolderKeys: () -> () = {}
    public var invokedDecryptAndStoreFolderKeysfunction = false
    public var invokedDecryptAndStoreFolderKeysCount = 0
    public var invokedDecryptAndStoreFolderKeysParameters: (shareId: String, folders: [Folder])?
    public var invokedDecryptAndStoreFolderKeysParametersList = [(shareId: String, folders: [Folder])]()

    public func decryptAndStoreFolderKeys(shareId: String, folders: [Folder]) async throws {
        invokedDecryptAndStoreFolderKeysfunction = true
        invokedDecryptAndStoreFolderKeysCount += 1
        invokedDecryptAndStoreFolderKeysParameters = (shareId, folders)
        if let error = decryptAndStoreFolderKeysShareIdFoldersThrowableError7 {
            throw error
        }
        closureDecryptAndStoreFolderKeys()
    }
    // MARK: - getContainerKey
    public var getContainerKeyContainerIdKeyRotationThrowableError8: Error?
    public var closureGetContainerKey: () -> () = {}
    public var invokedGetContainerKeyfunction = false
    public var invokedGetContainerKeyCount = 0
    public var invokedGetContainerKeyParameters: (containerId: String, keyRotation: Int64?)?
    public var invokedGetContainerKeyParametersList = [(containerId: String, keyRotation: Int64?)]()
    public nonisolated(unsafe) var stubbedGetContainerKeyResult: (any CryptographicKeyProtocol)!

    public func getContainerKey(containerId: String, keyRotation: Int64?) async throws -> any CryptographicKeyProtocol {
        invokedGetContainerKeyfunction = true
        invokedGetContainerKeyCount += 1
        invokedGetContainerKeyParameters = (containerId, keyRotation)
        if let error = getContainerKeyContainerIdKeyRotationThrowableError8 {
            throw error
        }
        closureGetContainerKey()
        return stubbedGetContainerKeyResult
    }
}
