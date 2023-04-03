//
// OrganizationProvider.swift
// Proton Pass - Created on 03/04/2023.
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

import ProtonCore_Authentication
import ProtonCore_DataModel
import ProtonCore_Services

public enum OrganizationProvider {
    /// Return `nil` if user is not subscribed, `OrganizationLite` object otherwise
    public static func getOrganization(apiService: APIService) async throws -> OrganizationLite? {
        let user = try await getUser(apiService: apiService)
        guard user.subscribed > 0 else { return nil }
        return try await apiService.exec(endpoint: GetOrganizationEndpoint()).organization
    }
}

private extension OrganizationProvider {
    static func getUser(apiService: APIService) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            let authenticator = Authenticator(api: apiService)
            authenticator.getUserInfo { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
