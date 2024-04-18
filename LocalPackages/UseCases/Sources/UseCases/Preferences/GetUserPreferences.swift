//
// GetUserPreferences.swift
// Proton Pass - Created on 12/04/2024.
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

import Client
import Entities
import Foundation

/// Get the current `UserPreferences`, return the default value if `nil`
public protocol GetUserPreferencesUseCase: Sendable {
    func execute() -> UserPreferences
}

public extension GetUserPreferencesUseCase {
    func callAsFunction() -> UserPreferences {
        execute()
    }
}

public final class GetUserPreferences: GetUserPreferencesUseCase {
    private let manager: any PreferencesManagerProtocol

    public init(manager: any PreferencesManagerProtocol) {
        self.manager = manager
    }

    public func execute() -> UserPreferences {
        manager.userPreferences.unwrapped()
    }
}
