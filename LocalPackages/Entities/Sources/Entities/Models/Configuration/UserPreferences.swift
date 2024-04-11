//
// UserPreferences.swift
// Proton Pass - Created on 27/03/2024.
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

/// Preferences bound to a specific user
public struct UserPreferences: Codable, Equatable, Sendable {
    /// Searchable items via Spotlight
    public var spotlightEnabled: Bool

    /// Spotlight indexable item content type
    public var spotlightSearchableContent: SpotlightSearchableContent

    /// Spotlight indexable vaults
    public var spotlightSearchableVaults: SpotlightSearchableVaults

    public init(spotlightEnabled: Bool,
                spotlightSearchableContent: SpotlightSearchableContent,
                spotlightSearchableVaults: SpotlightSearchableVaults) {
        self.spotlightEnabled = spotlightEnabled
        self.spotlightSearchableContent = spotlightSearchableContent
        self.spotlightSearchableVaults = spotlightSearchableVaults
    }
}

private extension UserPreferences {
    enum Default {
        static let spotlightEnabled = false
        static let spotlightSearchableContent: SpotlightSearchableContent = .title
        static let spotlightSearchableVaults: SpotlightSearchableVaults = .all
    }

    enum CodingKeys: String, CodingKey {
        case spotlightEnabled
        case spotlightSearchableContent
        case spotlightSearchableVaults
    }
}

public extension UserPreferences {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let spotlightEnabled = try container.decodeIfPresent(Bool.self, forKey: .spotlightEnabled)
        let spotlightSearchableContent = try container.decodeIfPresent(SpotlightSearchableContent.self,
                                                                       forKey: .spotlightSearchableContent)
        let spotlightSearchableVaults = try container.decodeIfPresent(SpotlightSearchableVaults.self,
                                                                      forKey: .spotlightSearchableVaults)
        self.init(spotlightEnabled: spotlightEnabled ?? Default.spotlightEnabled,
                  spotlightSearchableContent: spotlightSearchableContent ?? Default.spotlightSearchableContent,
                  spotlightSearchableVaults: spotlightSearchableVaults ?? Default.spotlightSearchableVaults)
    }

    static var `default`: Self {
        .init(spotlightEnabled: Default.spotlightEnabled,
              spotlightSearchableContent: Default.spotlightSearchableContent,
              spotlightSearchableVaults: Default.spotlightSearchableVaults)
    }
}

extension UserPreferences: SpotlightSettingsProvider {}
