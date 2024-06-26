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
    var currentActiveUser: CurrentValueSubject<UserData?, Never> { get }

    func setUp() async throws
    func getActiveUserData() async throws -> UserData?
    func getUnwrappedActiveUserData() async throws -> UserData
    func add(userData: UserData, isActive: Bool) async throws
    func switchActiveUser(with userId: String) async throws
    func getAllUser() async throws -> [UserData]
    func remove(userId: String) async throws
    func getActiveUserId() async throws -> String
    nonisolated func setUserData(_ userData: UserData, isActive: Bool)
}

public extension UserManagerProtocol {
    var activeUserId: String? {
        currentActiveUser.value?.user.ID
    }

    func addAndMarkAsActive(userData: UserData) async throws {
        try await add(userData: userData, isActive: true)
    }
}

public actor UserManager: UserManagerProtocol {
    public let currentActiveUser = CurrentValueSubject<UserData?, Never>(nil)
    private var userDatas = [UserData]()

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
        userDatas = try await userDataDatasource.getAll()

        let activeUserId = activeUserIdDatasource.getActiveUserId()
        currentActiveUser.send(userDatas.getActiveUser(userId: activeUserId))
        didSetUp = true
    }

    func getActiveUserData() async throws -> UserData? {
        await assertDidSetUp()

        if userDatas.isEmpty {
            activeUserIdDatasource.removeActiveUserId()
            throw PassError.userManager(.activeUserIdAvailableButNoUserDataFound)
        }

        guard let activeUserId else {
            return updateNewActiveUser()
        }

        guard let activeUserData = userDatas.getActiveUser(userId: activeUserId) else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        if currentActiveUser.value?.user.ID != activeUserData.user.ID {
            currentActiveUser.send(activeUserData)
        }
        return activeUserData
    }

    func getUnwrappedActiveUserData() async throws -> UserData {
        guard let userData = try await getActiveUserData() else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        return userData
    }

    func add(userData: UserData, isActive: Bool = true) async throws {
        await assertDidSetUp()

        try await userDataDatasource.upsert(userData)
        userDatas = try await userDataDatasource.getAll()

        // User data is being updated and should be updated in currentActiveUser
        if let activeUserId,
           activeUserId == userData.user.ID, !isActive {
            currentActiveUser.send(userData)
        }

        guard isActive else {
            return
        }
        currentActiveUser.send(userData)
        activeUserIdDatasource.updateActiveUserId(userData.user.ID)
    }

    func remove(userId: String) async throws {
        await assertDidSetUp()

        try await userDataDatasource.remove(userId: userId)
        userDatas = try await userDataDatasource.getAll()

        if activeUserId == userId {
            activeUserIdDatasource.removeActiveUserId()
            updateNewActiveUser()
        }
    }

    func switchActiveUser(with newActiveUserId: String) async throws {
        await assertDidSetUp()

        let userDatas = try await userDataDatasource.getAll()
        guard let activeUserData = userDatas.getActiveUser(userId: newActiveUserId) else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        currentActiveUser.send(activeUserData)
        activeUserIdDatasource.updateActiveUserId(newActiveUserId)
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

    @discardableResult
    func updateNewActiveUser() -> UserData? {
        let newActiveUser = userDatas.first
        currentActiveUser.send(newActiveUser)
        let id = newActiveUser?.user.ID
        if let id {
            activeUserIdDatasource.updateActiveUserId(id)
        }
        return newActiveUser
    }
}

private extension [UserData] {
    func getActiveUser(userId: String?) -> UserData? {
        self.first { $0.user.ID == userId }
    }
}
