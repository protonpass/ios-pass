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
import CoreData
import Foundation

public final class LocalUserEventIdDatasourceProtocolMock: @unchecked Sendable, LocalUserEventIdDatasourceProtocol {

    public init() {}

    // MARK: - getLastEventId
    public var getLastEventIdUserIdThrowableError1: Error?
    public var closureGetLastEventId: () -> () = {}
    public var invokedGetLastEventIdfunction = false
    public var invokedGetLastEventIdCount = 0
    public var invokedGetLastEventIdParameters: (userId: String, Void)?
    public var invokedGetLastEventIdParametersList = [(userId: String, Void)]()
    public var stubbedGetLastEventIdResult: String?

    public func getLastEventId(userId: String) async throws -> String? {
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
    // MARK: - upsertLastEventId
    public var upsertLastEventIdUserIdLastEventIdThrowableError2: Error?
    public var closureUpsertLastEventId: () -> () = {}
    public var invokedUpsertLastEventIdfunction = false
    public var invokedUpsertLastEventIdCount = 0
    public var invokedUpsertLastEventIdParameters: (userId: String, lastEventId: String)?
    public var invokedUpsertLastEventIdParametersList = [(userId: String, lastEventId: String)]()

    public func upsertLastEventId(userId: String, lastEventId: String) async throws {
        invokedUpsertLastEventIdfunction = true
        invokedUpsertLastEventIdCount += 1
        invokedUpsertLastEventIdParameters = (userId, lastEventId)
        invokedUpsertLastEventIdParametersList.append((userId, lastEventId))
        if let error = upsertLastEventIdUserIdLastEventIdThrowableError2 {
            throw error
        }
        closureUpsertLastEventId()
    }
    // MARK: - removeLastEventId
    public var removeLastEventIdUserIdThrowableError3: Error?
    public var closureRemoveLastEventId: () -> () = {}
    public var invokedRemoveLastEventIdfunction = false
    public var invokedRemoveLastEventIdCount = 0
    public var invokedRemoveLastEventIdParameters: (userId: String, Void)?
    public var invokedRemoveLastEventIdParametersList = [(userId: String, Void)]()

    public func removeLastEventId(userId: String) async throws {
        invokedRemoveLastEventIdfunction = true
        invokedRemoveLastEventIdCount += 1
        invokedRemoveLastEventIdParameters = (userId, ())
        invokedRemoveLastEventIdParametersList.append((userId, ()))
        if let error = removeLastEventIdUserIdThrowableError3 {
            throw error
        }
        closureRemoveLastEventId()
    }
}
