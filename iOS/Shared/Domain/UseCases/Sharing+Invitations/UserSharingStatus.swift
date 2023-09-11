//
//
// UserSharingStatus.swift
// Proton Pass - Created on 21/07/2023.
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
import ProtonCoreLogin

// sourcery: AutoMockable
protocol UserSharingStatusUseCase: Sendable {
    func execute() async -> Bool
}

extension UserSharingStatusUseCase {
    func callAsFunction() async -> Bool {
        await execute()
    }
}

final class UserSharingStatus: @unchecked Sendable, UserSharingStatusUseCase {
    private let getFeatureFlagStatus: GetFeatureFlagStatusUseCase
    private let passPlanRepository: PassPlanRepositoryProtocol
    private let logger: Logger

    init(getFeatureFlagStatus: GetFeatureFlagStatusUseCase,
         passPlanRepository: PassPlanRepositoryProtocol,
         logManager: LogManagerProtocol) {
        self.getFeatureFlagStatus = getFeatureFlagStatus
        self.passPlanRepository = passPlanRepository
        logger = Logger(manager: logManager)
    }

    func execute() async -> Bool {
        do {
            let isEnabled = try await getFeatureFlagStatus(with: FeatureFlagType.passSharingV1)
            let plan = try await passPlanRepository.getPlan()
            return isEnabled && !plan.isFreeUser
        } catch {
            logger.error(error)
            return false
        }
    }
}
