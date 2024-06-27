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
    func addAndMarkAsActive(userData: UserData) async throws
    func update(userData: UserData) async throws
    func switchActiveUser(with userId: String) async throws
    func getAllUser() async throws -> [UserData]
    func remove(userId: String) async throws
    func getActiveUserId() async throws -> String
    nonisolated func setUserData(_ userData: UserData)
}

public extension UserManagerProtocol {
    var activeUserId: String? {
        currentActiveUser.value?.user.ID
    }
}

public actor UserManager: UserManagerProtocol {
    public let currentActiveUser = CurrentValueSubject<UserData?, Never>(nil)
    private var userDatas = [UserProfile]()

    private let userDataDatasource: any LocalUserDataDatasourceProtocol
    private let logger: Logger
    private var didSetUp = false

    public init(userDataDatasource: any LocalUserDataDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.userDataDatasource = userDataDatasource
        logger = .init(manager: logManager)
    }
}

public extension UserManager {
    func setUp() async throws {
        userDatas = try await userDataDatasource.getAll()
        currentActiveUser.send(userDatas.getActiveUser?.userdata)
        didSetUp = true
    }

    func getActiveUserData() async throws -> UserData? {
        await assertDidSetUp()

        if userDatas.isEmpty {
            throw PassError.userManager(.noUserDataFound)
        }

        guard let activeUserData = userDatas.getActiveUser?.userdata else {
            throw PassError.userManager(.userDatasAvailableButNoActiveUserId)
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

    func getAllUser() async -> [UserData] {
        await assertDidSetUp()

        return userDatas.map(\.userdata)
    }

    func getActiveUserId() async throws -> String {
        await assertDidSetUp()
        guard let id = try await getActiveUserData()?.user.ID else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        return id
    }

    func addAndMarkAsActive(userData: UserData) async throws {
        await assertDidSetUp()

        try await userDataDatasource.upsert(userData)
        try await switchActiveUser(with: userData.user.ID)
    }

    func update(userData: UserData) async throws {
        try await userDataDatasource.upsert(userData)
        userDatas = try await userDataDatasource.getAll()
        if let activeUserId,
           activeUserId == userData.user.ID {
            currentActiveUser.send(userData)
        }
    }

    /// Remove user profile from database and memory. If the user being removed if the current active user it sets
    /// a new active user
    /// - Parameter userId: The id of the user to remove
    func remove(userId: String) async throws {
        await assertDidSetUp()

        try await userDataDatasource.remove(userId: userId)
        userDatas = try await userDataDatasource.getAll()

        if userDatas.getActiveUser == nil, let newActiveUser = userDatas.first {
            try await switchActiveUser(with: newActiveUser.userdata.user.ID)
        }
    }

    func switchActiveUser(with newActiveUserId: String) async throws {
        await assertDidSetUp()

        try await userDataDatasource.updateNewActiveUser(userId: newActiveUserId)

        userDatas = try await userDataDatasource.getAll()
        guard let activeUserData = userDatas.getActiveUser?.userdata else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        currentActiveUser.send(activeUserData)
    }
}

public extension UserManager {
    nonisolated func setUserData(_ userData: UserData) {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                try await addAndMarkAsActive(userData: userData)
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
}

private extension [UserProfile] {
    var getActiveUser: UserProfile? {
        self.first { $0.isActive }
    }
}
