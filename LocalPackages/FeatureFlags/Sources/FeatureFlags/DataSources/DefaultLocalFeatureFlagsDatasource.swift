//
// DefaultLocalFeatureFlagsDatasource.swift
// Proton - Created on 29/09/2023.
// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton.
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

public actor DefaultLocalFeatureFlagsDatasource: LocalFeatureFlagsProtocol {
    private var currentFlags: [String: FeatureFlags]

    public init(currentFlags: [String: FeatureFlags] = [String: FeatureFlags]()) {
        self.currentFlags = currentFlags
    }

    public func getFeatureFlags(userId: String) async throws -> FeatureFlags? {
        currentFlags[userId]
    }

    public func upsertFlags(_ flags: FeatureFlags, userId: String) async throws {
        currentFlags[userId] = flags
    }

    public func cleanAllFlags() async {
        currentFlags = [:]
    }

    public func cleanFlags(for userId: String) async {
        currentFlags.removeValue(forKey: userId)
    }
}
