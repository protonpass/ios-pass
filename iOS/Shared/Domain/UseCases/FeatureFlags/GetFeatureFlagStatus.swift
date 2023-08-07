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

import Client
import Core

// sourcery: AutoMockable
protocol GetFeatureFlagStatusUseCase: Sendable {
    func execute(with flag: FeatureFlagType) async throws -> Bool
}

extension GetFeatureFlagStatusUseCase {
    func callAsFunction(with flag: FeatureFlagType) async throws -> Bool {
        try await execute(with: flag)
    }
}

final class GetFeatureFlagStatus: @unchecked Sendable, GetFeatureFlagStatusUseCase {
    private let featureFlagsRepository: FeatureFlagsRepositoryProtocol

    init(featureFlagsRepository: FeatureFlagsRepositoryProtocol) {
        self.featureFlagsRepository = featureFlagsRepository
    }

    func execute(with flag: FeatureFlagType) async throws -> Bool {
        let flags = try await featureFlagsRepository.getFlags()
        return flags.isFlagEnable(for: flag)
    }
}
