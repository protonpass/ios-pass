//
// LocalTimestampDatasource.swift
// Proton Pass - Created on 01/07/2026.
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

import Foundation

// sourcery: AutoMockable
public protocol LocalTimestampDatasourceProtocol: Sendable {
    func getTimestamp(key: String) -> Int?
    func setTimestamp(_ value: Int?, key: String)
}

public final class LocalTimestampDatasource: LocalTimestampDatasourceProtocol {
    private let userDefault: UserDefaults

    public init(userDefault: UserDefaults) {
        self.userDefault = userDefault
    }
}

public extension LocalTimestampDatasource {
    func getTimestamp(key: String) -> Int? {
        guard userDefault.object(forKey: key) is Int else {
            return nil
        }
        return userDefault.integer(forKey: key)
    }

    func setTimestamp(_ value: Int?, key: String) {
        if let value {
            userDefault.set(value, forKey: key)
        } else {
            userDefault.removeObject(forKey: key)
        }
    }
}
