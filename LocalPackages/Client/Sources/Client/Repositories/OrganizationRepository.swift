//
// OrganizationRepository.swift
// Proton Pass - Created on 19/03/2024.
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

import Core
import Entities
import Foundation

public protocol OrganizationRepositoryProtocol: Sendable {
    /// Get from local, refresh if not exist
    /// Could be nil if the user is not in business plan
    func getOrganization() async throws -> Organization?

    /// Refresh and save to local database
    /// Could be nil if the user is not in business plan
    @discardableResult
    func refreshOrganization() async throws -> Organization?
}

public actor OrganizationRepository: OrganizationRepositoryProtocol {
    private let localDatasource: any LocalOrganizationDatasourceProtocol
    private let remoteDatasource: any RemoteOrganizationDatasourceProtocol
    private let userDataProvider: any UserDataProvider
    private let logger: Logger

    public init(localDatasource: any LocalOrganizationDatasourceProtocol,
                remoteDatasource: any RemoteOrganizationDatasourceProtocol,
                userDataProvider: any UserDataProvider,
                logManager: any LogManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.userDataProvider = userDataProvider
        logger = .init(manager: logManager)
    }
}

public extension OrganizationRepository {
    func getOrganization() async throws -> Organization? {
        let userId = try userDataProvider.getUserId()
        logger.trace("Getting organization userId \(userId)")
        if let organization = try await localDatasource.getOrganization(userId: userId) {
            logger.info("Found local organization userId \(userId)")
            return organization
        }

        logger.trace("Found no local organization userId \(userId)")
        return try await refreshOrganization()
    }

    func refreshOrganization() async throws -> Organization? {
        let userId = try userDataProvider.getUserId()
        logger.trace("Refreshing organization userId \(userId)")
        if let organization = try await remoteDatasource.getOrganization() {
            logger.trace("Refreshed organization userId \(userId). Upserting to local database.")
            try await localDatasource.upsertOrganization(organization, userId: userId)
            logger.trace("Refreshed organization userId \(userId). Upserted to local database.")
            return organization
        }
        logger.info("Refreshed and found no organization userId \(userId)")
        return nil
    }
}
