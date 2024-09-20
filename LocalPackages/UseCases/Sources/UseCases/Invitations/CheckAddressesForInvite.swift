//
// CheckAddressesForInvite.swift
// Proton Pass - Created on 07/03/2024.
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
import Entities
import Foundation

public protocol CheckAddressesForInviteUseCase: Sendable {
    func execute(shareId: String, emails: [String]) async throws -> CheckAddressesResult
}

public extension CheckAddressesForInviteUseCase {
    func callAsFunction(shareId: String, emails: [String]) async throws -> CheckAddressesResult {
        try await execute(shareId: shareId, emails: emails)
    }
}

public final class CheckAddressesForInvite: CheckAddressesForInviteUseCase {
    private let userManager: any UserManagerProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let organizationRepository: any OrganizationRepositoryProtocol
    private let shareInviteRepository: any ShareInviteRepositoryProtocol

    public init(userManager: any UserManagerProtocol,
                accessRepository: any AccessRepositoryProtocol,
                organizationRepository: any OrganizationRepositoryProtocol,
                shareInviteRepository: any ShareInviteRepositoryProtocol) {
        self.userManager = userManager
        self.accessRepository = accessRepository
        self.organizationRepository = organizationRepository
        self.shareInviteRepository = shareInviteRepository
    }

    public func execute(shareId: String, emails: [String]) async throws -> CheckAddressesResult {
        let plan = try await accessRepository.getPlan(userId: nil)

        guard plan.isBusinessUser else {
            // Not business user => no restriction
            return .valid
        }

        let userId = try await userManager.getActiveUserId()
        guard let organization = try await organizationRepository.refreshOrganization(userId: userId) else {
            assertionFailure("Organization must be not nil for business user")
            throw PassError.organizationNotFound
        }

        if organization.settings?.shareMode == .unrestricted {
            return .valid
        }

        let validAddresses = try await shareInviteRepository.checkAddresses(shareId: shareId,
                                                                            emails: emails)

        let invalidAddresses = emails.filter { !validAddresses.contains($0) }
        return invalidAddresses.isEmpty ? .valid : .invalid(invalidAddresses)
    }
}
