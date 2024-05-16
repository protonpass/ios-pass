//
// UserManager.swift
// Proton Pass - Created on 14/05/2024.
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

// Remove later
// periphery:ignore:all
@preconcurrency import Combine
import Core
import Entities
import Foundation
import ProtonCoreLogin

public protocol UserManagerProtocol: Sendable {
    var userDatas: CurrentValueSubject<[UserData], Never> { get }
    var activeUserId: CurrentValueSubject<String?, Never> { get }

    func setUp() async throws
    func getActiveUserData() async throws -> UserData?
    func addAndMarkAsActive(userData: UserData) async throws
    /// Remove the user with given `userId`
    /// If this user is active, mark the latest user as active and return if any
    func remove(userId: String) async throws -> UserData?
}

public actor UserManager: Sendable, UserManagerProtocol {
    public let userDatas = CurrentValueSubject<[UserData], Never>([])
    public let activeUserId = CurrentValueSubject<String?, Never>(nil)

    private let userDataDatasource: any LocalUserDataDatasourceProtocol
    private let activeUserIdDatasource: any LocalActiveUserIdDatasourceProtocol
    private let logger: Logger
    private var didSetUp = false

    public init(userDataDatasource: any LocalUserDataDatasourceProtocol,
                activeUserIdDatasource: any LocalActiveUserIdDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.userDataDatasource = userDataDatasource
        self.activeUserIdDatasource = activeUserIdDatasource
        logger = .init(manager: logManager)
    }
}

public extension UserManager {
    func setUp() async throws {
        let userDatas = try await userDataDatasource.getAll()
        self.userDatas.send(userDatas)

        let activeUserId = activeUserIdDatasource.getActiveUserId()
        self.activeUserId.send(activeUserId)

        didSetUp = true
    }

    func getActiveUserData() async throws -> UserData? {
        assertDidSetUp()
        let userDatas = userDatas.value

        guard let activeId = activeUserIdDatasource.getActiveUserId() else {
            if !userDatas.isEmpty {
                throw PassError.userManager(.userDatasAvailableButNoActiveUserId)
            }
            return nil
        }

        if userDatas.isEmpty {
            activeUserIdDatasource.removeActiveUserId()
            throw PassError.userManager(.activeUserIdAvailableButNoUserDataFound)
        }

        guard let activeUserData = userDatas.first(where: { $0.user.ID == activeId }) else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        return activeUserData
    }

    func addAndMarkAsActive(userData: UserData) async throws {
        assertDidSetUp()

        try await userDataDatasource.upsert(userData)
        let userDatas = try await userDataDatasource.getAll()
        self.userDatas.send(userDatas)

        let id = userData.user.ID
        activeUserIdDatasource.updateActiveUserId(id)
        activeUserId.send(id)
    }

    func remove(userId: String) async throws -> UserData? {
        assertDidSetUp()

        try await userDataDatasource.remove(userId: userId)
        let userDatas = try await userDataDatasource.getAll()
        self.userDatas.send(userDatas)

        guard activeUserIdDatasource.getActiveUserId() == userId,
              let newActiveUser = userDatas.last else {
            return nil
        }
        activeUserIdDatasource.updateActiveUserId(newActiveUser.user.ID)
        return newActiveUser
    }
}

private extension UserManager {
    func assertDidSetUp() {
        assert(didSetUp, "UserManager not set up. Call setUp() function as soon as possible.")
        if !didSetUp {
            logger.error("UserManager not set up")
        }
    }
}
