//
// FeatureFlagsRepositoryProtocolMock.swift
// Proton Pass - Created on 24/06/2026.
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

import ProtonCoreFeatureFlags
import ProtonCoreUtilities

public final class FeatureFlagsRepositoryMock: FeatureFlagsRepositoryProtocol {
    public var flagsUpdates: AsyncStream<String> {
        let (stream, _) = AsyncStream.makeStream(of: String.self)
        return stream
    }
    
    public init() {}

    public func updateLocalDataSource(_ localDataSource: Atomic<any LocalFeatureFlagsDataSourceProtocol>) {}
    public func setUserId(_ userId: String) {}
    public func fetchFlags() async throws {}
    public func setFlagOverride(_ flag: any FeatureFlagTypeProtocol, _ overrideWithValue: Bool) {}
    public func resetFlagOverride(_ flag: any FeatureFlagTypeProtocol) {}
    public func resetFlags() {}
    public func resetFlags(for userId: String) {}
    public func clearUserId() {}
    public func resetOverrides() {}
}
