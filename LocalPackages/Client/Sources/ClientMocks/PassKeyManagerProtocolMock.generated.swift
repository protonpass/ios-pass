// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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
    public var getShareKeyShareIdKeyRotationThrowableError1: Error?
    public var closureGetShareKey: () -> () = {}
    public var invokedGetShareKeyfunction = false
    public var invokedGetShareKeyCount = 0
    public var invokedGetShareKeyParameters: (shareId: String, keyRotation: Int64)?
    public var invokedGetShareKeyParametersList = [(shareId: String, keyRotation: Int64)]()
    public var stubbedGetShareKeyResult: DecryptedShareKey!

    public func getShareKey(shareId: String, keyRotation: Int64) async throws -> DecryptedShareKey {
        invokedGetShareKeyfunction = true
        invokedGetShareKeyCount += 1
        invokedGetShareKeyParameters = (shareId, keyRotation)
        invokedGetShareKeyParametersList.append((shareId, keyRotation))
        if let error = getShareKeyShareIdKeyRotationThrowableError1 {
            throw error
        }
        closureGetShareKey()
        return stubbedGetShareKeyResult
    }
    // MARK: - getLatestShareKey
    public var getLatestShareKeyShareIdThrowableError2: Error?
    public var closureGetLatestShareKey: () -> () = {}
    public var invokedGetLatestShareKeyfunction = false
    public var invokedGetLatestShareKeyCount = 0
    public var invokedGetLatestShareKeyParameters: (shareId: String, Void)?
    public var invokedGetLatestShareKeyParametersList = [(shareId: String, Void)]()
    public var stubbedGetLatestShareKeyResult: DecryptedShareKey!

    public func getLatestShareKey(shareId: String) async throws -> DecryptedShareKey {
        invokedGetLatestShareKeyfunction = true
        invokedGetLatestShareKeyCount += 1
        invokedGetLatestShareKeyParameters = (shareId, ())
        invokedGetLatestShareKeyParametersList.append((shareId, ()))
        if let error = getLatestShareKeyShareIdThrowableError2 {
            throw error
        }
        closureGetLatestShareKey()
        return stubbedGetLatestShareKeyResult
    }
    // MARK: - getLatestItemKey
    public var getLatestItemKeyShareIdItemIdThrowableError3: Error?
    public var closureGetLatestItemKey: () -> () = {}
    public var invokedGetLatestItemKeyfunction = false
    public var invokedGetLatestItemKeyCount = 0
    public var invokedGetLatestItemKeyParameters: (shareId: String, itemId: String)?
    public var invokedGetLatestItemKeyParametersList = [(shareId: String, itemId: String)]()
    public var stubbedGetLatestItemKeyResult: DecryptedItemKey!

    public func getLatestItemKey(shareId: String, itemId: String) async throws -> DecryptedItemKey {
        invokedGetLatestItemKeyfunction = true
        invokedGetLatestItemKeyCount += 1
        invokedGetLatestItemKeyParameters = (shareId, itemId)
        invokedGetLatestItemKeyParametersList.append((shareId, itemId))
        if let error = getLatestItemKeyShareIdItemIdThrowableError3 {
            throw error
        }
        closureGetLatestItemKey()
        return stubbedGetLatestItemKeyResult
    }
}
