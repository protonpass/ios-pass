//
// PassPlanRepository.swift
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

import Core

public protocol PassPlanRepositoryDelegate: AnyObject {
    func passPlanRepositoryDidUpdateToNewPlan()
}

// sourcery: AutoMockable
public protocol PassPlanRepositoryProtocol: AnyObject, Sendable {
    var localDatasource: LocalPassPlanDatasourceProtocol { get }
    var remoteDatasource: RemotePassPlanDatasourceProtocol { get }
    var userId: String { get }
    var logger: Logger { get }

    var delegate: PassPlanRepositoryDelegate? { get set }

    /// Get from local, refresh if not exist
    func getPlan() async throws -> PassPlan

    @discardableResult
    func refreshPlan() async throws -> PassPlan
}

public extension PassPlanRepositoryProtocol {
    func getPlan() async throws -> PassPlan {
        logger.trace("Getting plan for user \(userId)")
        if let passPlan = try await localDatasource.getPassPlan(userId: userId) {
            logger.trace("Found local plan for user \(userId)")
            return passPlan
        }

        logger.trace("No local plan found for user \(userId). Refreshing...")
        let refreshedPassPlan = try await refreshPlan()
        return refreshedPassPlan
    }

    @discardableResult
    func refreshPlan() async throws -> PassPlan {
        logger.trace("Refreshing plan for user \(userId)")
        let passPlan = try await remoteDatasource.getPassPlan()

        if let currentLocalPlan = try await localDatasource.getPassPlan(userId: userId),
           currentLocalPlan != passPlan {
            logger.info("New plan found")
            delegate?.passPlanRepositoryDidUpdateToNewPlan()
        }

        logger.trace("Upserting plan for user \(userId)")
        try await localDatasource.upsert(passPlan: passPlan, userId: userId)

        logger.info("Refreshed plan for user \(userId)")
        return passPlan
    }
}

public final class PassPlanRepository: PassPlanRepositoryProtocol {
    public let localDatasource: LocalPassPlanDatasourceProtocol
    public let remoteDatasource: RemotePassPlanDatasourceProtocol
    public let userId: String
    public let logger: Logger

    public weak var delegate: PassPlanRepositoryDelegate?

    public init(localDatasource: LocalPassPlanDatasourceProtocol,
                remoteDatasource: RemotePassPlanDatasourceProtocol,
                userId: String,
                logManager: LogManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.userId = userId
        logger = .init(manager: logManager)
    }
}
