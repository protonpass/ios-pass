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

// swiftlint:disable:next todo
// TODO: Make the repository `UserManagerProtocol` independant
// sourcery: AutoMockable
public protocol AccessRepositoryProtocol: AnyObject, Sendable {
    /// `Access` of current user
    var access: CurrentValueSubject<UserAccess?, Never> { get }

    /// `Access` of all users
    var accesses: CurrentValueSubject<[UserAccess], Never> { get }

    var didUpdateToNewPlan: PassthroughSubject<Void, Never> { get }

    /// Get from local, refresh if not exist
    func getAccess(userId: String?) async throws -> UserAccess

    /// Refresh the access of current users
    @discardableResult
    func refreshAccess(userId: String?) async throws -> UserAccess

    /// Load local accesses onto memory for quick access
    func loadAccesses() async throws

    func updateProtonAddressesMonitor(userId: String?, monitored: Bool) async throws
    func updateAliasesMonitor(userId: String?, monitored: Bool) async throws
    func getPassUserInformation(userId: String) async throws -> PassUserInformations
}

public extension AccessRepositoryProtocol {
    /// Conveniently get the plan of current access
    func getPlan(userId: String?) async throws -> Plan {
        try await getAccess(userId: userId).access.plan
    }
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
    func getAccess(userId: String?) async throws -> UserAccess {
        let userId = if let userId {
            userId
        } else {
            try await userManager.getActiveUserId()
        }
        logger.trace("Getting access for user \(userId)")
        if let localAccess = try await localDatasource.getAccess(userId: userId) {
            logger.trace("Found local access for user \(userId)")
            await MainActor.run {
                access.send(localAccess)
            }
            return localAccess
        }

        logger.trace("No local access found for user \(userId). Refreshing...")
        return try await refreshAccess(userId: userId)
    }

    @discardableResult
    func refreshAccess(userId: String?) async throws -> UserAccess {
        let userId = if let userId {
            userId
        } else {
            try await userManager.getActiveUserId()
        }
        logger.trace("Refreshing access for user \(userId)")
        let remoteAccess = try await remoteDatasource.getAccess(userId: userId)
        let userAccess = UserAccess(userId: userId, access: remoteAccess)
        await MainActor.run {
            access.send(userAccess)
        }

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

    func updateProtonAddressesMonitor(userId: String?, monitored: Bool) async throws {
        try await updatePassMonitorState(userId: userId, request: .protonAddress(monitored))
    }

    func updateAliasesMonitor(userId: String?, monitored: Bool) async throws {
        try await updatePassMonitorState(userId: userId, request: .aliases(monitored))
    }

    func getPassUserInformation(userId: String) async throws -> PassUserInformations {
        logger.trace("Getting information for user \(userId)")
        if let localInfos = try await localDatasource.getPassUserInformations(userId: userId) {
            logger.trace("Found local infos for user \(userId)")
            return localInfos
        } else {
            let infos = try await remoteDatasource.getUserPassInformations(userId: userId)
            try await localDatasource.upsert(informations: infos, userId: userId)
            return infos
        }
    }
}

private extension AccessRepository {
    func updatePassMonitorState(userId: String?, request: UpdateMonitorStateRequest) async throws {
        let userId = if let userId {
            userId
        } else {
            try await userManager.getActiveUserId()
        }
        logger.trace("Updating monitor state for user \(userId)")
        var access = try await getAccess(userId: userId)
        let updatedMonitor = try await remoteDatasource.updatePassMonitorState(userId: userId, request: request)
        access.access.monitor = updatedMonitor

        logger.trace("Upserting access for user \(userId)")
        try await localDatasource.upsert(access: access)
        logger.trace("Upserted monitor state for user \(userId)")
        self.access.send(access)
    }
}
