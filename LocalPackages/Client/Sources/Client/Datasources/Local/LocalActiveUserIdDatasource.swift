//
// LocalActiveUserIdDatasource.swift
// Proton Pass - Created on 16/05/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

// Remove later
// periphery:ignore:all
import Foundation

private let kActiveUserIdKey = "ActiveUserId"

// sourcery: AutoMockable
public protocol LocalActiveUserIdDatasourceProtocol: Sendable {
    func getActiveUserId() -> String?
    func updateActiveUserId(_ id: String)
    func removeActiveUserId()
}

public final class LocalActiveUserIdDatasource: LocalActiveUserIdDatasourceProtocol {
    private let userDefault: UserDefaults

    public init(userDefault: UserDefaults) {
        self.userDefault = userDefault
    }
}

public extension LocalActiveUserIdDatasource {
    func getActiveUserId() -> String? {
        userDefault.string(forKey: kActiveUserIdKey)
    }

    func updateActiveUserId(_ id: String) {
        userDefault.set(id, forKey: kActiveUserIdKey)
    }

    func removeActiveUserId() {
        userDefault.set(nil, forKey: kActiveUserIdKey)
    }
}
