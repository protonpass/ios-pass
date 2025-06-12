// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
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

public final class ShareEventIDRepositoryProtocolMock: @unchecked Sendable, ShareEventIDRepositoryProtocol {

    public init() {}

    // MARK: - getLastEventId
    public var getLastEventIdForceRefreshUserIdShareIdThrowableError1: Error?
    public var closureGetLastEventId: () -> () = {}
    public var invokedGetLastEventIdfunction = false
    public var invokedGetLastEventIdCount = 0
    public var invokedGetLastEventIdParameters: (forceRefresh: Bool, userId: String, shareId: String)?
    public var invokedGetLastEventIdParametersList = [(forceRefresh: Bool, userId: String, shareId: String)]()
    public var stubbedGetLastEventIdResult: String!

    public func getLastEventId(forceRefresh: Bool, userId: String, shareId: String) async throws -> String {
        invokedGetLastEventIdfunction = true
        invokedGetLastEventIdCount += 1
        invokedGetLastEventIdParameters = (forceRefresh, userId, shareId)
        invokedGetLastEventIdParametersList.append((forceRefresh, userId, shareId))
        if let error = getLastEventIdForceRefreshUserIdShareIdThrowableError1 {
            throw error
        }
        closureGetLastEventId()
        return stubbedGetLastEventIdResult
    }
    // MARK: - upsertLastEventId
    public var upsertLastEventIdUserIdShareIdLastEventIdThrowableError2: Error?
    public var closureUpsertLastEventId: () -> () = {}
    public var invokedUpsertLastEventIdfunction = false
    public var invokedUpsertLastEventIdCount = 0
    public var invokedUpsertLastEventIdParameters: (userId: String, shareId: String, lastEventId: String)?
    public var invokedUpsertLastEventIdParametersList = [(userId: String, shareId: String, lastEventId: String)]()

    public func upsertLastEventId(userId: String, shareId: String, lastEventId: String) async throws {
        invokedUpsertLastEventIdfunction = true
        invokedUpsertLastEventIdCount += 1
        invokedUpsertLastEventIdParameters = (userId, shareId, lastEventId)
        invokedUpsertLastEventIdParametersList.append((userId, shareId, lastEventId))
        if let error = upsertLastEventIdUserIdShareIdLastEventIdThrowableError2 {
            throw error
        }
        closureUpsertLastEventId()
    }
}
