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
@preconcurrency import ProtonCoreLogin

// sourcery: AutoMockable
public protocol UserManagerProtocol: Sendable, UserManagerProvider {
    var currentActiveUser: CurrentValueSubject<UserData?, Never> { get }
    var allUserAccounts: CurrentValueSubject<[UserData], Never> { get }

    func setUp() async throws
    func getActiveUserData() async throws -> UserData?
    func upsertAndMarkAsActive(userData: UserData) async throws

    /// When `onMemory` is `true`, we don't save the active user ID to the database
    /// This is to let extensions dynamically switch between accounts when creating items
    /// as we don't want extensions to affect the current active user.
    func switchActiveUser(with userId: String, onMemory: Bool) async throws

    func getAllUsers() async throws -> [UserData]
    func remove(userId: String) async throws
    func cleanAllUsers() async throws
    nonisolated func setUserData(_ userData: UserData)
}

public extension UserManagerProtocol {
    var activeUserId: String? {
        currentActiveUser.value?.user.ID
    }

    func getUnwrappedActiveUserData() async throws -> UserData {
        guard let userData = try await getActiveUserData() else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        return userData
    }

    func getUserData(_ userId: String) async throws -> UserData? {
        try await getAllUsers().first(where: { $0.user.ID == userId })
    }

    func getActiveUserId() async throws -> String {
        guard let id = try await getActiveUserData()?.user.ID else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        return id
    }
}

public actor UserManager: UserManagerProtocol {
    public nonisolated let currentActiveUser = CurrentValueSubject<UserData?, Never>(nil)
    public nonisolated let allUserAccounts: CurrentValueSubject<[UserData], Never> = .init([])

    private var userProfiles = [UserProfile]()
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
        userProfiles = try await userDataDatasource.getAll()
        allUserAccounts.send(userProfiles.userDatas)
        await publishNewActiveUser(userProfiles.activeUser?.userdata)
        didSetUp = true
    }

    func getActiveUserData() async throws -> UserData? {
        assertDidSetUp()

        if userProfiles.isEmpty {
            return nil
        }

        guard let activeUserData = userProfiles.activeUser?.userdata else {
            throw PassError.userManager(.userDatasAvailableButNoActiveUserId)
        }
        return activeUserData
    }

    func getAllUsers() async -> [UserData] {
        assertDidSetUp()

        return userProfiles.userDatas
    }

    func upsertAndMarkAsActive(userData: UserData) async throws {
        assertDidSetUp()

        try await userDataDatasource.upsert(userData)
        try await switchActiveUser(with: userData.user.ID, onMemory: false)
    }

    /// Remove user profile from database and memory. If the user being removed if the current active user it sets
    /// a new active user
    /// - Parameter userId: The id of the user to remove
    func remove(userId: String) async throws {
        assertDidSetUp()

        try await userDataDatasource.remove(userId: userId)

        try await updateCachedUserAccounts()

        if userProfiles.activeUser == nil, let newActiveUser = userProfiles.first {
            try await switchActiveUser(with: newActiveUser.userdata.user.ID, onMemory: false)
        }
    }

    func switchActiveUser(with newActiveUserId: String, onMemory: Bool) async throws {
        assertDidSetUp()
        if onMemory {
            if let tempActiveUserData = userProfiles.first(where: { $0.userdata.user.ID == newActiveUserId }) {
                userProfiles = userProfiles.map {
                    .init(userdata: $0.userdata,
                          isActive: newActiveUserId == $0.userdata.user.ID,
                          updateTime: $0.updateTime)
                }
                await publishNewActiveUser(tempActiveUserData.userdata)
            }
            return
        }

        try await userDataDatasource.updateNewActiveUser(userId: newActiveUserId)
        try await updateCachedUserAccounts()

        guard let activeUserData = userProfiles.activeUser?.userdata else {
            throw PassError.userManager(.activeUserDataNotFound)
        }
        await publishNewActiveUser(activeUserData)
    }

    func cleanAllUsers() async throws {
        try await userDataDatasource.removeAll()
        await publishNewActiveUser(nil)
        allUserAccounts.send([])
        userProfiles = []
    }
}

// MARK: - Utils

private extension UserManager {
    func updateCachedUserAccounts() async throws {
        userProfiles = try await userDataDatasource.getAll()
        allUserAccounts.send(userProfiles.userDatas)
    }

    /// Make sure to publish on main actor because other main actors listen to these changes and update the UI
    @MainActor
    func publishNewActiveUser(_ user: UserData?) {
        currentActiveUser.send(user)
    }
}

public extension UserManager {
    nonisolated func setUserData(_ userData: UserData) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                try await upsertAndMarkAsActive(userData: userData)
            } catch {
                logger.error(error)
            }
        }
    }
}

private extension UserManager {
    func assertDidSetUp() {
        assert(didSetUp, "UserManager not set up. Call setUp() function as soon as possible.")
    }
}

private extension [UserProfile] {
    var activeUser: UserProfile? {
        self.first { $0.isActive }
    }

    var userDatas: [UserData] {
        self.sorted(by: { $0.isActive && !$1.isActive }).map(\.userdata)
    }
}
