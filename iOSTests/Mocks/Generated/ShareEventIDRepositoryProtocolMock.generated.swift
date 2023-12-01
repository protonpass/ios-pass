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
// swiftlint:disable all

@testable import Client
import Core
import CoreData
import ProtonCoreNetworking
import ProtonCoreServices

final class ShareEventIDRepositoryProtocolMock: @unchecked Sendable, ShareEventIDRepositoryProtocol {
    // MARK: - getLastEventId
    var getLastEventIdForceRefreshUserIdShareIdThrowableError: Error?
    var closureGetLastEventId: () -> () = {}
    var invokedGetLastEventIdfunction = false
    var invokedGetLastEventIdCount = 0
    var invokedGetLastEventIdParameters: (forceRefresh: Bool, userId: String, shareId: String)?
    var invokedGetLastEventIdParametersList = [(forceRefresh: Bool, userId: String, shareId: String)]()
    var stubbedGetLastEventIdResult: String!

    func getLastEventId(forceRefresh: Bool, userId: String, shareId: String) async throws -> String {
        invokedGetLastEventIdfunction = true
        invokedGetLastEventIdCount += 1
        invokedGetLastEventIdParameters = (forceRefresh, userId, shareId)
        invokedGetLastEventIdParametersList.append((forceRefresh, userId, shareId))
        if let error = getLastEventIdForceRefreshUserIdShareIdThrowableError {
            throw error
        }
        closureGetLastEventId()
        return stubbedGetLastEventIdResult
    }
    // MARK: - upsertLastEventId
    var upsertLastEventIdUserIdShareIdLastEventIdThrowableError: Error?
    var closureUpsertLastEventId: () -> () = {}
    var invokedUpsertLastEventIdfunction = false
    var invokedUpsertLastEventIdCount = 0
    var invokedUpsertLastEventIdParameters: (userId: String, shareId: String, lastEventId: String)?
    var invokedUpsertLastEventIdParametersList = [(userId: String, shareId: String, lastEventId: String)]()

    func upsertLastEventId(userId: String, shareId: String, lastEventId: String) async throws {
        invokedUpsertLastEventIdfunction = true
        invokedUpsertLastEventIdCount += 1
        invokedUpsertLastEventIdParameters = (userId, shareId, lastEventId)
        invokedUpsertLastEventIdParametersList.append((userId, shareId, lastEventId))
        if let error = upsertLastEventIdUserIdShareIdLastEventIdThrowableError {
            throw error
        }
        closureUpsertLastEventId()
    }
}
