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

// periphery:ignore:all

import Client
import Core
import Foundation
import ProtonCoreFeatureFlags

// sourcery: AutoMockable
public protocol GetFeatureFlagStatusUseCase: Sendable {
    func execute(for flag: any FeatureFlagTypeProtocol) -> Bool
}

public extension GetFeatureFlagStatusUseCase {
    func callAsFunction(for flag: any FeatureFlagTypeProtocol) -> Bool {
        execute(for: flag)
    }
}

public final class GetFeatureFlagStatus: @unchecked Sendable, GetFeatureFlagStatusUseCase {
    private let bundle: Bundle
    private let userDefault: UserDefaults
    private let userManager: any UserManagerProtocol
    private let featureFlagsRepository: any FeatureFlagsRepositoryProtocol

    public init(bundle: Bundle = .main,
                userDefault: UserDefaults = kSharedUserDefaults,
                userManager: any UserManagerProtocol,
                repository: any FeatureFlagsRepositoryProtocol) {
        self.bundle = bundle
        self.userDefault = userDefault
        self.userManager = userManager
        featureFlagsRepository = repository
    }

    public func execute(for flag: any FeatureFlagTypeProtocol) -> Bool {
        if bundle.isQaBuild, userDefault.bool(forKey: flag.rawValue) {
            return true
        }

        if let userId = userManager.activeUserId {
            featureFlagsRepository.setUserId(userId)
        }
        return featureFlagsRepository.isEnabled(flag, reloadValue: true)
    }
}
