//
// Spotlight.swift
// Proton Pass - Created on 29/01/2024.
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

import Foundation

public enum SpotlightSearchableContent: Int, Codable, CaseIterable, Sendable {
    case title = 0
    case titleAndNote = 1
    case allExceptSensitiveData = 2

    var includeNote: Bool {
        if case .title = self {
            return false
        }
        return true
    }

    var includeCustomData: Bool {
        if case .allExceptSensitiveData = self {
            return true
        }
        return false
    }
}

public enum SpotlightSearchableVaults: Int, Codable, CaseIterable, Sendable {
    case all = 0
    case selected = 1
}

public protocol SpotlightSettingsProvider: Sendable {
    var spotlightEnabled: Bool { get }
    var spotlightSearchableContent: SpotlightSearchableContent { get }
    var spotlightSearchableVaults: SpotlightSearchableVaults { get }
}
