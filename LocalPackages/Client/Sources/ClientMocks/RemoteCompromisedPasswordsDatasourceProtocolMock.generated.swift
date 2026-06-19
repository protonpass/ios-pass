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
import Entities
import Foundation

public final class RemoteCompromisedPasswordsDatasourceProtocolMock: @unchecked Sendable, RemoteCompromisedPasswordsDatasourceProtocol {

    public init() {}

    // MARK: - lastChange
    public var lastChangeThrowableError1: Error?
    public var closureLastChange: () -> () = {}
    public var invokedLastChangefunction = false
    public var invokedLastChangeCount = 0
    public nonisolated(unsafe) var stubbedLastChangeResult: Int!

    public func lastChange() async throws -> Int {
        invokedLastChangefunction = true
        invokedLastChangeCount += 1
        if let error = lastChangeThrowableError1 {
            throw error
        }
        closureLastChange()
        return stubbedLastChangeResult
    }
    // MARK: - query
    public var queryPrefix6EtagThrowableError2: Error?
    public var closureQuery: () -> () = {}
    public var invokedQueryfunction = false
    public var invokedQueryCount = 0
    public var invokedQueryParameters: (prefix6: String, etag: String?)?
    public var invokedQueryParametersList = [(prefix6: String, etag: String?)]()
    public nonisolated(unsafe) var stubbedQueryResult: CompromisedRangeResponse!

    public func query(prefix6: String, etag: String?) async throws -> CompromisedRangeResponse {
        invokedQueryfunction = true
        invokedQueryCount += 1
        invokedQueryParameters = (prefix6, etag)
        if let error = queryPrefix6EtagThrowableError2 {
            throw error
        }
        closureQuery()
        return stubbedQueryResult
    }
}
