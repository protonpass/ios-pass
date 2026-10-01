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
import Foundation

public final class LocalTimestampDatasourceProtocolMock: @unchecked Sendable, LocalTimestampDatasourceProtocol {

    public init() {}

    // MARK: - getTimestamp
    public var closureGetTimestamp: () -> () = {}
    public var invokedGetTimestampfunction = false
    public var invokedGetTimestampCount = 0
    public var invokedGetTimestampParameters: (key: String, Void)?
    public var invokedGetTimestampParametersList = [(key: String, Void)]()
    public nonisolated(unsafe) var stubbedGetTimestampResult: Int?

    public func getTimestamp(key: String) -> Int? {
        invokedGetTimestampfunction = true
        invokedGetTimestampCount += 1
        invokedGetTimestampParameters = (key, ())
        closureGetTimestamp()
        return stubbedGetTimestampResult
    }
    // MARK: - setTimestamp
    public var closureSetTimestamp: () -> () = {}
    public var invokedSetTimestampfunction = false
    public var invokedSetTimestampCount = 0
    public var invokedSetTimestampParameters: (value: Int?, key: String)?
    public var invokedSetTimestampParametersList = [(value: Int?, key: String)]()

    public func setTimestamp(_ value: Int?, key: String) {
        invokedSetTimestampfunction = true
        invokedSetTimestampCount += 1
        invokedSetTimestampParameters = (value, key)
        closureSetTimestamp()
    }
}
