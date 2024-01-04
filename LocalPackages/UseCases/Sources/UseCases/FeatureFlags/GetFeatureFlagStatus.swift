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
    func execute(for flag: any FeatureFlagTypeProtocol) -> Bool
}

public extension GetFeatureFlagStatusUseCase {
    func callAsFunction(with flag: any FeatureFlagTypeProtocol) async -> Bool {
        await execute(with: flag)
    }

    func callAsFunction(with flag: any FeatureFlagTypeProtocol) -> Bool {
        execute(for: flag)
    }
}

public final class GetFeatureFlagStatus: @unchecked Sendable, GetFeatureFlagStatusUseCase {
    private let featureFlagsRepository: any FeatureFlagsRepositoryProtocol
    private let logger: Logger

    public init(repository: any FeatureFlagsRepositoryProtocol,
                logManager: any LogManagerProtocol) {
        featureFlagsRepository = repository
        logger = .init(manager: logManager)
    }

    public func execute(with flag: any FeatureFlagTypeProtocol) async -> Bool {
        featureFlagsRepository.isEnabled(flag, reloadValue: true)
    }

    public func execute(for flag: any FeatureFlagTypeProtocol) -> Bool {
        featureFlagsRepository.isEnabled(flag, reloadValue: true)
    }
}
