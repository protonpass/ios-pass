//
// CheckFlagForMultiUsers.swift
// Proton Pass - Created on 28/08/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import ProtonCoreFeatureFlags
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUtilities

private struct FeatureFlagRequest: Request {
    var path: String {
        "/feature/v2/frontend"
    }

    var isAuth: Bool {
        true
    }
}

private struct FeatureFlagResponse: Decodable {
    public let code: Int
    public let toggles: [FeatureFlag]

    public init(code: Int, toggles: [FeatureFlag]) {
        self.code = code
        self.toggles = toggles
    }
}

/// Return `true` if at least 1 of the user has the flag enabled
public protocol CheckFlagForMultiUsersUseCase: Sendable {
    func execute(flag: String, userIds: [String]) async throws -> Bool
}

public extension CheckFlagForMultiUsersUseCase {
    func callAsFunction(flag: String, userIds: [String]) async throws -> Bool {
        try await execute(flag: flag, userIds: userIds)
    }
}

public final class CheckFlagForMultiUsers: CheckFlagForMultiUsersUseCase {
    private let apiServicing: any APIManagerProtocol

    public init(apiServicing: any APIManagerProtocol) {
        self.apiServicing = apiServicing
    }

    public func execute(flag: String, userIds: [String]) async throws -> Bool {
        for userId in userIds {
            let apiService = try apiServicing.getApiService(userId: userId)
            let request = FeatureFlagRequest()
            let (_, response): (_, FeatureFlagResponse) = try await apiService.perform(request: request)
            if response.toggles.contains(where: { $0.name == flag && $0.enabled }) {
                return true
            }
        }
        return false
    }
}
