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
    var localFeatureFlagsDatasource: LocalFeatureFlagsDatasourceProtocol { get }
    var remoteFeatureFlagsDatasource: RemoteFeatureFlagsDatasourceProtocol { get }
    var userId: String { get }
    var logger: Logger { get }

    /// Get from local, refresh if not exist
    func getFlags() async throws -> FeatureFlags

    @discardableResult
    func refreshFlags() async throws -> FeatureFlags
}

public extension FeatureFlagsRepositoryProtocol {
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
        let creditCardV1 = try await remoteFeatureFlagsDatasource.getFlag(type: .creditCardV1)

        logger.trace("Getting remote custom fields flag for user \(userId)")
        let customFields = try await remoteFeatureFlagsDatasource.getFlag(type: .customFields)

        logger.trace("Got remote flags for user \(userId). Upserting to local database.")
        let flags = FeatureFlags(creditCardV1: creditCardV1, customFields: customFields)
        try await localFeatureFlagsDatasource.upsertFlags(flags, userId: userId)

        return flags
    }
}

public final class FeatureFlagsRepository: FeatureFlagsRepositoryProtocol {
    public let localFeatureFlagsDatasource: LocalFeatureFlagsDatasourceProtocol
    public let remoteFeatureFlagsDatasource: RemoteFeatureFlagsDatasourceProtocol
    public let userId: String
    public let logger: Logger

    public init(localFeatureFlagsDatasource: LocalFeatureFlagsDatasourceProtocol,
                remoteFeatureFlagsDatasource: RemoteFeatureFlagsDatasourceProtocol,
                userId: String,
                logManager: LogManager) {
        self.localFeatureFlagsDatasource = localFeatureFlagsDatasource
        self.remoteFeatureFlagsDatasource = remoteFeatureFlagsDatasource
        self.userId = userId
        self.logger = .init(manager: logManager)
    }
}
