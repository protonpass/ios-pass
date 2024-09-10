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

    /// Whether the user has extra password enabled or not
    public var extraPasswordEnabled: Bool

    /// Keep track of failed Proton password verification attempts (to enable extra password)
    public var protonPasswordFailedVerificationCount: Int

    /// `shareId` of the last selected vault. `nil` if all vaults are selected
    public var lastSelectedShareId: String?

    /// `shareId` of the last created item
    public var lastCreatedItemShareId: String?

    public init(spotlightEnabled: Bool,
                spotlightSearchableContent: SpotlightSearchableContent,
                spotlightSearchableVaults: SpotlightSearchableVaults,
                extraPasswordEnabled: Bool,
                protonPasswordFailedVerificationCount: Int,
                lastSelectedShareId: String?,
                lastCreatedItemShareId: String?) {
        self.spotlightEnabled = spotlightEnabled
        self.spotlightSearchableContent = spotlightSearchableContent
        self.spotlightSearchableVaults = spotlightSearchableVaults
        self.extraPasswordEnabled = extraPasswordEnabled
        self.protonPasswordFailedVerificationCount = protonPasswordFailedVerificationCount
        self.lastSelectedShareId = lastSelectedShareId
        self.lastCreatedItemShareId = lastCreatedItemShareId
    }
}

private extension UserPreferences {
    enum Default {
        static let spotlightEnabled = false
        static let spotlightSearchableContent: SpotlightSearchableContent = .title
        static let spotlightSearchableVaults: SpotlightSearchableVaults = .all
        static let extraPasswordEnabled = false
        static let protonPasswordFailedVerificationCount = 0
        static let lastSelectedShareId: String? = nil
        static let lastCreatedItemShareId: String? = nil
    }

    enum CodingKeys: String, CodingKey {
        case spotlightEnabled
        case spotlightSearchableContent
        case spotlightSearchableVaults
        case extraPasswordEnabled
        case protonPasswordFailedVerificationCount
        case lastSelectedShareId
        case lastCreatedItemShareId
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
        let extraPasswordEnabled = try container.decodeIfPresent(Bool.self,
                                                                 forKey: .extraPasswordEnabled)
        let protonPasswordFailedVerificationCount =
            try container.decodeIfPresent(Int.self, forKey: .protonPasswordFailedVerificationCount)
        let lastSelectedShareId = try container.decodeIfPresent(String?.self, forKey: .lastSelectedShareId)
        let lastCreatedItemShareId = try container.decodeIfPresent(String?.self, forKey: .lastCreatedItemShareId)
        self.init(spotlightEnabled: spotlightEnabled ?? Default.spotlightEnabled,
                  spotlightSearchableContent: spotlightSearchableContent ?? Default.spotlightSearchableContent,
                  spotlightSearchableVaults: spotlightSearchableVaults ?? Default.spotlightSearchableVaults,
                  extraPasswordEnabled: extraPasswordEnabled ?? Default.extraPasswordEnabled,
                  protonPasswordFailedVerificationCount: protonPasswordFailedVerificationCount
                      ?? Default.protonPasswordFailedVerificationCount,
                  lastSelectedShareId: lastSelectedShareId ?? Default.lastSelectedShareId,
                  lastCreatedItemShareId: lastCreatedItemShareId ?? Default.lastCreatedItemShareId)
    }
}

extension UserPreferences: Defaultable {
    public static var `default`: Self {
        .init(spotlightEnabled: Default.spotlightEnabled,
              spotlightSearchableContent: Default.spotlightSearchableContent,
              spotlightSearchableVaults: Default.spotlightSearchableVaults,
              extraPasswordEnabled: Default.extraPasswordEnabled,
              protonPasswordFailedVerificationCount: Default.protonPasswordFailedVerificationCount,
              lastSelectedShareId: Default.lastSelectedShareId,
              lastCreatedItemShareId: Default.lastCreatedItemShareId)
    }
}

extension UserPreferences: SpotlightSettingsProvider {}
