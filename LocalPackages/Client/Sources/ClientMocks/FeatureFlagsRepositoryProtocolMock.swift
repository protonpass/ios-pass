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
import ProtonCoreServices
import ProtonCoreUtilities

/// Every requirement of `FeatureFlagsRepositoryProtocol` must be implemented here, including
/// the ones that look like they already have a default. `ProtonCoreFeatureFlags` declares
/// `isEnabled`, `getFlag` and `setApiService` as requirements *and* supplies same-signature
/// protocol extensions whose only purpose is a default argument, so their bodies call
/// themselves. A missing witness therefore binds to an infinitely recursive default and
/// overflows the stack at the first call instead of failing as an unimplemented mock.
public final class FeatureFlagsRepositoryMock: FeatureFlagsRepositoryProtocol {
    private let isEnabledStub: @Sendable (any FeatureFlagTypeProtocol) -> Bool

    private let (stream, continuation) = AsyncStream.makeStream(of: String.self)

    public var flagsUpdates: AsyncStream<String> { stream }

    public init(isEnabled: @escaping @Sendable (any FeatureFlagTypeProtocol) -> Bool = { _ in false }) {
        isEnabledStub = isEnabled
    }

    public func isEnabled(_ flag: any FeatureFlagTypeProtocol, reloadValue: Bool) -> Bool {
        isEnabledStub(flag)
    }

    public func isEnabled(_ flag: any FeatureFlagTypeProtocol,
                          for userId: String?,
                          reloadValue: Bool) -> Bool {
        isEnabledStub(flag)
    }

    public func getFlag(_ flag: any FeatureFlagTypeProtocol,
                        for userId: String?,
                        reloadValue: Bool) -> FeatureFlag? {
        FeatureFlag(name: flag.rawValue, enabled: isEnabledStub(flag), variant: nil)
    }

    public func setApiService(_ apiService: any APIService,
                              completionExecutor: CompletionBlockExecutor) {}

    public func updateLocalDataSource(_ localDataSource: Atomic<any LocalFeatureFlagsDataSourceProtocol>) {}
    public func setUserId(_ userId: String) {}
    public func fetchFlags() async throws {}
    public func setFlagOverride(_ flag: any FeatureFlagTypeProtocol, _ overrideWithValue: Bool) {}
    public func resetFlagOverride(_ flag: any FeatureFlagTypeProtocol) {}
    public func resetFlags() {}
    public func resetFlags(for userId: String) {}
    public func clearUserId() {}
    public func resetOverrides() {}

    public func simulateFlagsUpdate(for userId: String) {
        continuation.yield(userId)
    }
}
