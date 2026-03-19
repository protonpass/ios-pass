//
// GetOrganizationSettings.swift
// Proton Pass - Created on 18/03/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Entities

public protocol GetOrganizationSettingsUseCase: Sendable {
    func execute() async throws -> Organization.Settings?
}

public extension GetOrganizationSettingsUseCase {
    func callAsFunction() async throws -> Organization.Settings? {
        try await execute()
    }
}

public final class GetOrganizationSettings: GetOrganizationSettingsUseCase {
    private let accessRepository: any AccessRepositoryProtocol
    private let organizationRepository: any OrganizationRepositoryProtocol

    public init(accessRepository: any AccessRepositoryProtocol,
                organizationRepository: any OrganizationRepositoryProtocol) {
        self.accessRepository = accessRepository
        self.organizationRepository = organizationRepository
    }

    public func execute() async throws -> Organization.Settings? {
        if let access = accessRepository.access.value, access.access.plan.planType == .business,
           let organization = try await organizationRepository.getOrganization(userId: access.userId) {
            return organization.settings
        }
        return nil
    }
}
