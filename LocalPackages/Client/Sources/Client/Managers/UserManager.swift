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
import ProtonCoreNetworking

// sourcery:AutoMockable
public protocol UserManagerProtocol: Sendable {
    var userDatas: CurrentValueSubject<[UserData], Never> { get }
    var currentActiveUser: CurrentValueSubject<UserData?, Never> { get }
    var activeUserId: CurrentValueSubject<String?, Never> { get }

    func setUp() async throws
    func getActiveUserData() async throws -> UserData?
    func add(userData: UserData, isActive: Bool) async throws
    func switchActiveUser(with userId: String) async throws
    func getAllUser() async throws -> [UserData]
    func remove(userId: String) async throws
    func getActiveUserId() async throws -> String
    func getUserData() -> UserData?
    nonisolated func setUserData(_ userData: UserData, isActive: Bool)
    nonisolated func getActiveUserIdNonisolated() throws -> String
    nonisolated func getUnwrappedUserData() throws -> UserData
}

public extension UserManagerProtocol {
    func addAndMarkAsActive(userData: UserData) async throws {
        try await add(userData: userData, isActive: true)
    }

    func add(userData: UserData, isActive: Bool = true) async throws {
        try await add(userData: userData, isActive: isActive)
    }
}

public actor UserManager: UserManagerProtocol {
    public let userDatas = CurrentValueSubject<[UserData], Never>([])
    public let currentActiveUser = CurrentValueSubject<UserData?, Never>(nil)
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
        currentActiveUser.send(userDatas.first(where: { $0.user.ID == activeUserId }))
        didSetUp = true
    }

    func getActiveUserData() async throws -> UserData? {
        await assertDidSetUp()
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
        currentActiveUser.send(activeUserData)
        return activeUserData
    }

    func add(userData: UserData, isActive: Bool = true) async throws {
        await assertDidSetUp()

        try await userDataDatasource.upsert(userData)
        let userDatas = try await userDataDatasource.getAll()
        self.userDatas.send(userDatas)

        if let currentUserId = currentActiveUser.value?.user.ID,
           currentUserId == userData.user.ID {
            currentActiveUser.send(userData)
        }

        guard isActive else {
            return
        }
        let id = userData.user.ID
        activeUserIdDatasource.updateActiveUserId(id)
        activeUserId.send(id)
    }

    func remove(userId: String) async throws {
        await assertDidSetUp()

        try await userDataDatasource.remove(userId: userId)
        let updatedUserDatas = try await userDataDatasource.getAll()
        userDatas.send(updatedUserDatas)

        if activeUserId.value == userId {
            activeUserIdDatasource.removeActiveUserId()
            updateNewActiveUser(users: updatedUserDatas)
        }
    }

    func switchActiveUser(with newActiveUserId: String) async throws {
        await assertDidSetUp()

        let userDatas = try await userDataDatasource.getAll()
        guard let activeUserData = userDatas.first(where: { $0.user.ID == newActiveUserId }) else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        currentActiveUser.send(activeUserData)
        let id = activeUserData.user.ID
        activeUserIdDatasource.updateActiveUserId(id)
        activeUserId.send(id)
    }

    func getAllUser() async throws -> [UserData] {
        await assertDidSetUp()

        return try await userDataDatasource.getAll()
    }

    func getActiveUserId() async throws -> String {
        await assertDidSetUp()
        guard let id = try await getActiveUserData()?.user.ID else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        return id
    }
}

public extension UserManager {
    nonisolated func getUserData() -> UserData? {
        currentActiveUser.value
    }

    nonisolated func setUserData(_ userData: UserData, isActive: Bool = false) {
        Task {
            do {
                try await add(userData: userData, isActive: isActive)
            } catch {
                logger.error(error)
            }
        }
    }

    nonisolated func remove(userId: String) {
        Task {
            do {
                try await remove(userId: userId)
            } catch {
                logger.error(error)
            }
        }
    }

    nonisolated func getActiveUserIdNonisolated() throws -> String {
        guard let activeUserId = activeUserId.value else {
            throw PassError.noUserData
        }
        return activeUserId
    }

    nonisolated func getUnwrappedUserData() throws -> UserData {
        guard let userData = currentActiveUser.value else {
            throw PassError.noUserData
        }
        return userData
    }
}

private extension UserManager {
    func assertDidSetUp() async {
        // swiftlint:disable:next todo
        // TODO: this should not setup and only assert. We should spread repo lazy loading in the app
        if !didSetUp {
            do {
                try await setUp()
            } catch {
                assert(didSetUp, "UserManager not set up. Call setUp() function as soon as possible.")
            }
            logger.error("UserManager not set up")
        }
    }

    func updateNewActiveUser(users: [UserData]) {
        let newActiveUser = users.first
        currentActiveUser.send(newActiveUser)
        let id = newActiveUser?.user.ID
        if let id {
            activeUserIdDatasource.updateActiveUserId(id)
        }
        activeUserId.send(id)
    }
}
