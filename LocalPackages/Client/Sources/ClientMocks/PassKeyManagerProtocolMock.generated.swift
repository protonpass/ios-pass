// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
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
    public var stubbedGetShareKeyResult: DecryptedShareKey!

    public func getShareKey(userId: String, shareId: String, keyRotation: Int64) async throws -> DecryptedShareKey {
        invokedGetShareKeyfunction = true
        invokedGetShareKeyCount += 1
        invokedGetShareKeyParameters = (userId, shareId, keyRotation)
        invokedGetShareKeyParametersList.append((userId, shareId, keyRotation))
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
    public var stubbedGetLatestShareKeyResult: DecryptedShareKey!

    public func getLatestShareKey(userId: String, shareId: String) async throws -> DecryptedShareKey {
        invokedGetLatestShareKeyfunction = true
        invokedGetLatestShareKeyCount += 1
        invokedGetLatestShareKeyParameters = (userId, shareId)
        invokedGetLatestShareKeyParametersList.append((userId, shareId))
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
    public var invokedGetShareKeysParameters: (userId: String, share: Share, item: any ItemIdentifiable)?
    public var invokedGetShareKeysParametersList = [(userId: String, share: Share, item: any ItemIdentifiable)]()
    public var stubbedGetShareKeysResult: [any ShareKeyProtocol]!

    public func getShareKeys(userId: String, share: Share, item: any ItemIdentifiable) async throws -> [any ShareKeyProtocol] {
        invokedGetShareKeysfunction = true
        invokedGetShareKeysCount += 1
        invokedGetShareKeysParameters = (userId, share, item)
        invokedGetShareKeysParametersList.append((userId, share, item))
        if let error = getShareKeysUserIdShareItemThrowableError3 {
            throw error
        }
        closureGetShareKeys()
        return stubbedGetShareKeysResult
    }
    // MARK: - getLatestItemKey
    public var getLatestItemKeyUserIdShareIdItemIdThrowableError4: Error?
    public var closureGetLatestItemKey: () -> () = {}
    public var invokedGetLatestItemKeyfunction = false
    public var invokedGetLatestItemKeyCount = 0
    public var invokedGetLatestItemKeyParameters: (userId: String, shareId: String, itemId: String)?
    public var invokedGetLatestItemKeyParametersList = [(userId: String, shareId: String, itemId: String)]()
    public var stubbedGetLatestItemKeyResult: DecryptedItemKey!

    public func getLatestItemKey(userId: String, shareId: String, itemId: String) async throws -> DecryptedItemKey {
        invokedGetLatestItemKeyfunction = true
        invokedGetLatestItemKeyCount += 1
        invokedGetLatestItemKeyParameters = (userId, shareId, itemId)
        invokedGetLatestItemKeyParametersList.append((userId, shareId, itemId))
        if let error = getLatestItemKeyUserIdShareIdItemIdThrowableError4 {
            throw error
        }
        closureGetLatestItemKey()
        return stubbedGetLatestItemKeyResult
    }
    // MARK: - getItemKeys
    public var getItemKeysUserIdShareIdItemIdThrowableError5: Error?
    public var closureGetItemKeys: () -> () = {}
    public var invokedGetItemKeysfunction = false
    public var invokedGetItemKeysCount = 0
    public var invokedGetItemKeysParameters: (userId: String, shareId: String, itemId: String)?
    public var invokedGetItemKeysParametersList = [(userId: String, shareId: String, itemId: String)]()
    public var stubbedGetItemKeysResult: [DecryptedItemKey]!

    public func getItemKeys(userId: String, shareId: String, itemId: String) async throws -> [DecryptedItemKey] {
        invokedGetItemKeysfunction = true
        invokedGetItemKeysCount += 1
        invokedGetItemKeysParameters = (userId, shareId, itemId)
        invokedGetItemKeysParametersList.append((userId, shareId, itemId))
        if let error = getItemKeysUserIdShareIdItemIdThrowableError5 {
            throw error
        }
        closureGetItemKeys()
        return stubbedGetItemKeysResult
    }
    // MARK: - getItemKey
    public var getItemKeyUserIdShareIdItemIdKeyRotationThrowableError6: Error?
    public var closureGetItemKey: () -> () = {}
    public var invokedGetItemKeyfunction = false
    public var invokedGetItemKeyCount = 0
    public var invokedGetItemKeyParameters: (userId: String, shareId: String, itemId: String, keyRotation: Int64)?
    public var invokedGetItemKeyParametersList = [(userId: String, shareId: String, itemId: String, keyRotation: Int64)]()
    public var stubbedGetItemKeyResult: DecryptedItemKey!

    public func getItemKey(userId: String, shareId: String, itemId: String, keyRotation: Int64) async throws -> DecryptedItemKey {
        invokedGetItemKeyfunction = true
        invokedGetItemKeyCount += 1
        invokedGetItemKeyParameters = (userId, shareId, itemId, keyRotation)
        invokedGetItemKeyParametersList.append((userId, shareId, itemId, keyRotation))
        if let error = getItemKeyUserIdShareIdItemIdKeyRotationThrowableError6 {
            throw error
        }
        closureGetItemKey()
        return stubbedGetItemKeyResult
    }
}
