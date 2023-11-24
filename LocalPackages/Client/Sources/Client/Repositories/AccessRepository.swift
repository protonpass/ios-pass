//
// AccessRepository.swift
// Proton Pass - Created on 04/05/2023.
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

import Combine
import Core
import Entities

// sourcery: AutoMockable
public protocol AccessRepositoryProtocol: AnyObject, Sendable {
    var didUpdateToNewPlan: PassthroughSubject<Void, Never> { get }

    /// Get from local, refresh if not exist
    func getAccess() async throws -> Access

    /// Conveniently get the plan of current access
    func getPlan() async throws -> Plan

    @discardableResult
    func refreshAccess() async throws -> Access
}

public actor AccessRepository: AccessRepositoryProtocol {
    private let localDatasource: LocalAccessDatasourceProtocol
    private let remoteDatasource: RemoteAccessDatasourceProtocol
    private let userDataProvider: UserDataProvider
    private let logger: Logger

    public let didUpdateToNewPlan: PassthroughSubject<Void, Never> = .init()

    public init(localDatasource: LocalAccessDatasourceProtocol,
                remoteDatasource: RemoteAccessDatasourceProtocol,
                userDataProvider: UserDataProvider,
                logManager: LogManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.userDataProvider = userDataProvider
        logger = .init(manager: logManager)
    }
}

public extension AccessRepository {
    func getAccess() async throws -> Access {
        let userId = try userDataProvider.getUserId()
        logger.trace("Getting access for user \(userId)")
        if let localAccess = try await localDatasource.getAccess(userId: userId) {
            logger.trace("Found local access for user \(userId)")
            return localAccess
        }

        logger.trace("No local access found for user \(userId). Refreshing...")
        return try await refreshAccess()
    }

    func getPlan() async throws -> Plan {
        let userId = try userDataProvider.getUserId()
        logger.trace("Getting plan for user \(userId)")
        return try await getAccess().plan
    }

    @discardableResult
    func refreshAccess() async throws -> Access {
        let userId = try userDataProvider.getUserId()
        logger.trace("Refreshing access for user \(userId)")
        let remoteAccess = try await remoteDatasource.getAccess()

        if let localAccess = try await localDatasource.getAccess(userId: userId),
           localAccess.plan != remoteAccess.plan {
            logger.info("New plan found")
            didUpdateToNewPlan.send()
        }

        logger.trace("Upserting access for user \(userId)")
        try await localDatasource.upsert(access: remoteAccess, userId: userId)

        logger.info("Refreshed access for user \(userId)")
        return remoteAccess
    }
}
