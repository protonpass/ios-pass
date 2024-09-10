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

@preconcurrency import Combine
import Core
import Entities

// sourcery: AutoMockable
public protocol AccessRepositoryProtocol: AnyObject, Sendable {
    /// `Access` of current user
    var access: CurrentValueSubject<UserAccess?, Never> { get }

    /// `Access` of all users
    var accesses: CurrentValueSubject<[UserAccess], Never> { get }

    var didUpdateToNewPlan: PassthroughSubject<Void, Never> { get }

    /// Get from local, refresh if not exist
    func getAccess() async throws -> UserAccess

    /// Conveniently get the plan of current access
    func getPlan() async throws -> Plan

    /// Refresh the access of current users
    @discardableResult
    func refreshAccess() async throws -> UserAccess

    /// Load local accesses onto memory for quick access
    func loadAccesses() async throws

    func updateProtonAddressesMonitor(_ monitored: Bool) async throws
    func updateAliasesMonitor(_ monitored: Bool) async throws
}

public actor AccessRepository: AccessRepositoryProtocol {
    private let localDatasource: any LocalAccessDatasourceProtocol
    private let remoteDatasource: any RemoteAccessDatasourceProtocol
    private let userManager: any UserManagerProtocol
    private let logger: Logger

    public nonisolated let access: CurrentValueSubject<UserAccess?, Never> = .init(nil)
    public nonisolated let accesses: CurrentValueSubject<[UserAccess], Never> = .init([])

    public nonisolated let didUpdateToNewPlan: PassthroughSubject<Void, Never> = .init()

    public init(localDatasource: any LocalAccessDatasourceProtocol,
                remoteDatasource: any RemoteAccessDatasourceProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.userManager = userManager
        logger = .init(manager: logManager)
    }
}

public extension AccessRepository {
    func getAccess() async throws -> UserAccess {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Getting access for user \(userId)")
        if let localAccess = try await localDatasource.getAccess(userId: userId) {
            logger.trace("Found local access for user \(userId)")
            access.send(localAccess)
            return localAccess
        }

        logger.trace("No local access found for user \(userId). Refreshing...")
        return try await refreshAccess()
    }

    func getPlan() async throws -> Plan {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Getting plan for user \(userId)")
        return try await getAccess().access.plan
    }

    @discardableResult
    func refreshAccess() async throws -> UserAccess {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Refreshing access for user \(userId)")
        let remoteAccess = try await remoteDatasource.getAccess(userId: userId)
        let userAccess = UserAccess(userId: userId, access: remoteAccess)
        access.send(userAccess)

        if let localAccess = try await localDatasource.getAccess(userId: userId),
           localAccess.access.plan != remoteAccess.plan {
            logger.info("New plan found")
            await MainActor.run {
                didUpdateToNewPlan.send()
            }
        }

        logger.trace("Upserting access for user \(userId)")
        try await localDatasource.upsert(access: userAccess)

        logger.info("Refreshed access for user \(userId)")
        try await loadAccesses()
        return userAccess
    }

    func loadAccesses() async throws {
        let accesses = try await localDatasource.getAllAccesses()
        self.accesses.send(accesses)
    }

    func updateProtonAddressesMonitor(_ monitored: Bool) async throws {
        try await updatePassMonitorState(.protonAddress(monitored))
    }

    func updateAliasesMonitor(_ monitored: Bool) async throws {
        try await updatePassMonitorState(.aliases(monitored))
    }
}

private extension AccessRepository {
    func updatePassMonitorState(_ request: UpdateMonitorStateRequest) async throws {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Updating monitor state for user \(userId)")
        var access = try await getAccess()
        let updatedMonitor = try await remoteDatasource.updatePassMonitorState(userId: userId, request: request)
        access.access.monitor = updatedMonitor

        logger.trace("Upserting access for user \(userId)")
        try await localDatasource.upsert(access: access)
        logger.trace("Upserted monitor state for user \(userId)")
        self.access.send(access)
    }
}
