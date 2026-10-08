//
// MockLocalTimestampDatasource.swift
// Proton Pass - Created on 30/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import os

public final class MockLocalTimestampDatasource: LocalTimestampDatasourceProtocol {
    private let store = OSAllocatedUnfairLock(initialState: [String: Int]())

    public init() {}

    public func getTimestamp(key: String) -> Int? {
        store.withLock { $0[key] }
    }

    public func setTimestamp(_ value: Int?, key: String) {
        store.withLock { $0[key] = value }
    }
}
