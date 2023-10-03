//
// FeatureFlagsRepositoryProtocol.swift
// Proton - Created on 29/09/2023.
// Copyright (c) 2023 Proton Technologies AG
//
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

public protocol FeatureFlagsRepositoryProtocol: AnyObject {
    /// Get from local, refresh if not exist
    func getFlags() async throws -> FeatureFlags

    func getFlag(for key: any FeatureFlagTypeProtocol) async -> FeatureFlag?

    @discardableResult
    func refreshFlags() async throws -> FeatureFlags

    func isFlagEnable(for key: any FeatureFlagTypeProtocol) async -> Bool

    func resetFlags() async
    func resetFlags(for userId: String) async
}
