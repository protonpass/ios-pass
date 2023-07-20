//
// FeatureFlagsRepository.swift
// Proton Pass - Created on 09/06/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Core

public protocol FeatureFlagsRepositoryProtocol: AnyObject {
    /// Get from local, refresh if not exist
    func getFlags() async throws -> FeatureFlags

    @discardableResult
    func refreshFlags() async throws -> FeatureFlags
}

public final class FeatureFlagsRepository: FeatureFlagsRepositoryProtocol {
    private let localFeatureFlagsDatasource: LocalFeatureFlagsDatasourceProtocol
    private let remoteFeatureFlagsDatasource: RemoteFeatureFlagsDatasourceProtocol
    private let userId: String
    private let logger: Logger

    public init(localFeatureFlagsDatasource: LocalFeatureFlagsDatasourceProtocol,
                remoteFeatureFlagsDatasource: RemoteFeatureFlagsDatasourceProtocol,
                userId: String,
                logManager: LogManagerProtocol) {
        self.localFeatureFlagsDatasource = localFeatureFlagsDatasource
        self.remoteFeatureFlagsDatasource = remoteFeatureFlagsDatasource
        self.userId = userId
        logger = Logger(manager: logManager)
    }
}

public extension FeatureFlagsRepository {
    func getFlags() async throws -> FeatureFlags {
        logger.trace("Getting feature flags for user \(userId)")
        if let localFlags = try await localFeatureFlagsDatasource.getFeatureFlags(userId: userId) {
            logger.trace("Found local feature flags for user \(userId)")
            return localFlags
        }

        logger.debug("No local feature flags found for user \(userId). Getting from remote.")
        return try await refreshFlags()
    }

    func refreshFlags() async throws -> FeatureFlags {
        logger.trace("Getting remote credit card v1 flag for user \(userId)")
        let allflags = try await remoteFeatureFlagsDatasource.getFlags()

        logger.trace("Got remote flags for user \(userId). Upserting to local database.")

        let flags = filterPassFlags(from: allflags) // FeatureFlags(creditCardV1: creditCardV1)
        try await localFeatureFlagsDatasource.upsertFlags(flags, userId: userId)

        return flags
    }
}

private extension FeatureFlagsRepository {
    /// The new unleash feature flag endpoint doesn't filter flags on project base meaning we receive all proton
    /// flags we want to
    /// filter only the ones that are linked to pass
    /// The flag only appears if it is activated otherwise it it absent from the response
    func filterPassFlags(from flags: [FeatureFlag]) -> FeatureFlags {
        let currentPassFlags = flags.filter { element in
            FeatureFlagType(rawValue: element.name) != nil
        }
        return FeatureFlags(flags: currentPassFlags)
    }
}
