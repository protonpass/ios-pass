//
// UserPlanProvider.swift
// Proton Pass - Created on 24/04/2023.
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
import ProtonCore_Services

public enum UserPlan: Codable, Equatable {
    case free
    case paid(PlanLite)
    case subUser
}

public protocol UserPlanProviderProtocol {
    var apiService: APIService { get }
    var logger: Logger { get }

    func getUserPlan() async throws -> UserPlan
}

public extension UserPlanProviderProtocol {
    func getUserPlan() async throws -> UserPlan {
        logger.trace("Getting user plan by first getting user")
        let user = try await apiService.exec(endpoint: GetUserEndpoint()).user

        if user.type == 2 {
            logger.trace("User is a subuser")
            return .subUser
        }

        if user.subscribed > 0 {
            logger.trace("User is subscribed, getting plans")
            let subscription = try await apiService.exec(endpoint: GetSubscriptionEndpoint()).subscription
            let plans = subscription.plans
            if let primaryPlan = plans.first(where: { $0.isPrimary }) ?? plans.first {
                return .paid(primaryPlan)
            }
            logger.warning("User is subscribed but can not find any plans")
            // Should not happen
            return .free
        }
        logger.trace("User is a free user")
        return .free
    }
}

public final class UserPlanProvider: UserPlanProviderProtocol {
    public let apiService: APIService
    public let logger: Logger

    public init(apiService: APIService, logManager: LogManager) {
        self.apiService = apiService
        self.logger = .init(manager: logManager)
    }
}
