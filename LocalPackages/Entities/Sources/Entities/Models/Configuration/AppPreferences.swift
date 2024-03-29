//
// AppPreferences.swift
// Proton Pass - Created on 29/03/2024.
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

/// Application-wide preferences
public struct AppPreferences: Codable {
    /// The user is onboarded or not
    public var onboarded = false

    /// The time of the next telemetry event batch
    public var telemetryThreshold: TimeInterval?

    /// Number of created items from this device. Used to ask for review when appropriate.
    public var createdItemsCount = 0

    /// Keep track of dismissed banners so we don't show them again
    public var dismissedBannerIds: [String]
}
