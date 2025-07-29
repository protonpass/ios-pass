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

public final class RemoteUserEventsDatasourceProtocolMock: @unchecked Sendable, RemoteUserEventsDatasourceProtocol {

    public init() {}

    // MARK: - getLastEventId
    public var getLastEventIdUserIdThrowableError1: Error?
    public var closureGetLastEventId: () -> () = {}
    public var invokedGetLastEventIdfunction = false
    public var invokedGetLastEventIdCount = 0
    public var invokedGetLastEventIdParameters: (userId: String, Void)?
    public var invokedGetLastEventIdParametersList = [(userId: String, Void)]()
    public var stubbedGetLastEventIdResult: String!

    public func getLastEventId(userId: String) async throws -> String {
        invokedGetLastEventIdfunction = true
        invokedGetLastEventIdCount += 1
        invokedGetLastEventIdParameters = (userId, ())
        invokedGetLastEventIdParametersList.append((userId, ()))
        if let error = getLastEventIdUserIdThrowableError1 {
            throw error
        }
        closureGetLastEventId()
        return stubbedGetLastEventIdResult
    }
    // MARK: - getUserEvents
    public var getUserEventsUserIdLastEventIdThrowableError2: Error?
    public var closureGetUserEvents: () -> () = {}
    public var invokedGetUserEventsfunction = false
    public var invokedGetUserEventsCount = 0
    public var invokedGetUserEventsParameters: (userId: String, lastEventId: String)?
    public var invokedGetUserEventsParametersList = [(userId: String, lastEventId: String)]()
    public var stubbedGetUserEventsResult: UserEvents!

    public func getUserEvents(userId: String, lastEventId: String) async throws -> UserEvents {
        invokedGetUserEventsfunction = true
        invokedGetUserEventsCount += 1
        invokedGetUserEventsParameters = (userId, lastEventId)
        invokedGetUserEventsParametersList.append((userId, lastEventId))
        if let error = getUserEventsUserIdLastEventIdThrowableError2 {
            throw error
        }
        closureGetUserEvents()
        return stubbedGetUserEventsResult
    }
}
