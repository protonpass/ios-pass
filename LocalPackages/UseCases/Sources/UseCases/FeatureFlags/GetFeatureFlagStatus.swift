//
//
// GetFeatureFlagStatus.swift
// Proton Pass - Created on 02/08/2023.
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
//

import Core
import ProtonCoreFeatureFlags

// sourcery: AutoMockable
public protocol GetFeatureFlagStatusUseCase: Sendable {
    func execute(with flag: any FeatureFlagTypeProtocol) async -> Bool
}

public extension GetFeatureFlagStatusUseCase {
    func callAsFunction(with flag: any FeatureFlagTypeProtocol) async -> Bool {
        await execute(with: flag)
    }
}

public final class GetFeatureFlagStatus: @unchecked Sendable, GetFeatureFlagStatusUseCase {
    private let featureFlagsRepository: FeatureFlagsRepositoryProtocol
    private let userInformations: UserInformationProtocol
    private let logger: Logger

    public init(repository: FeatureFlagsRepositoryProtocol,
                userInfos: UserInformationProtocol,
                logManager: LogManagerProtocol) {
        featureFlagsRepository = repository
        userInformations = userInfos
        logger = .init(manager: logManager)
    }

    public func execute(with flag: any FeatureFlagTypeProtocol) async -> Bool {
        do {
            logger.trace("Getting feature flags for user \(userInformations.userId)")
            let flags = try await featureFlagsRepository.getFlags()
            logger.trace("Found local feature flags for user")
            return flags.isFlagEnabled(for: flag)
        } catch {
            logger.error(error)
            return false
        }
    }
}
