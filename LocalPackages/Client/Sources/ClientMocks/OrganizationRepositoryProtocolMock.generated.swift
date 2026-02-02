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
import Core
import Entities
import Foundation

public final class OrganizationRepositoryProtocolMock: @unchecked Sendable, OrganizationRepositoryProtocol {

    public init() {}

    // MARK: - getOrganization
    public var getOrganizationUserIdThrowableError1: Error?
    public var closureGetOrganization: () -> () = {}
    public var invokedGetOrganizationfunction = false
    public var invokedGetOrganizationCount = 0
    public var invokedGetOrganizationParameters: (userId: String, Void)?
    public var invokedGetOrganizationParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetOrganizationResult: Organization?

    public func getOrganization(userId: String) async throws -> Organization? {
        invokedGetOrganizationfunction = true
        invokedGetOrganizationCount += 1
        invokedGetOrganizationParameters = (userId, ())
        if let error = getOrganizationUserIdThrowableError1 {
            throw error
        }
        closureGetOrganization()
        return stubbedGetOrganizationResult
    }
    // MARK: - refreshOrganization
    public var refreshOrganizationUserIdThrowableError2: Error?
    public var closureRefreshOrganization: () -> () = {}
    public var invokedRefreshOrganizationfunction = false
    public var invokedRefreshOrganizationCount = 0
    public var invokedRefreshOrganizationParameters: (userId: String, Void)?
    public var invokedRefreshOrganizationParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedRefreshOrganizationResult: Organization?

    public func refreshOrganization(userId: String) async throws -> Organization? {
        invokedRefreshOrganizationfunction = true
        invokedRefreshOrganizationCount += 1
        invokedRefreshOrganizationParameters = (userId, ())
        if let error = refreshOrganizationUserIdThrowableError2 {
            throw error
        }
        closureRefreshOrganization()
        return stubbedRefreshOrganizationResult
    }
    // MARK: - getOrganizationKeys
    public var getOrganizationKeysUserIdThrowableError3: Error?
    public var closureGetOrganizationKeys: () -> () = {}
    public var invokedGetOrganizationKeysfunction = false
    public var invokedGetOrganizationKeysCount = 0
    public var invokedGetOrganizationKeysParameters: (userId: String, Void)?
    public var invokedGetOrganizationKeysParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetOrganizationKeysResult: OrganizationKey!

    public func getOrganizationKeys(userId: String) async throws -> OrganizationKey {
        invokedGetOrganizationKeysfunction = true
        invokedGetOrganizationKeysCount += 1
        invokedGetOrganizationKeysParameters = (userId, ())
        if let error = getOrganizationKeysUserIdThrowableError3 {
            throw error
        }
        closureGetOrganizationKeys()
        return stubbedGetOrganizationKeysResult
    }
}
