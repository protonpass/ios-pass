//
//
// LogOutUser.swift
// Proton Pass - Created on 17/07/2024.
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

import Client
import Entities
@preconcurrency import ProtonCoreFeatureFlags
import ProtonCoreLogin
import UIKit

public protocol LogOutUserUseCase: Sendable {
    @discardableResult
    func execute(userId: String) async throws -> Bool
}

public extension LogOutUserUseCase {
    @discardableResult
    func callAsFunction(userId: String) async throws -> Bool {
        try await execute(userId: userId)
    }
}

public final class LogOutUser: LogOutUserUseCase {
    private let userManager: any UserManagerProtocol
    private let syncEventLoop: any SyncEventLoopProtocol
    private let preferencesManager: any PreferencesManagerProtocol
    private let removeUserLocalData: any RemoveUserLocalDataUseCase
    private let featureFlagsRepository: any FeatureFlagsRepositoryProtocol
    private let passMonitorRepository: any PassMonitorRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let vaultsManager: any VaultsManagerProtocol
    private let apiManager: any APIManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let credentialManager: any CredentialManagerProtocol
    private let switchUser: any SwitchUserUseCase

    public init(userManager: any UserManagerProtocol,
                syncEventLoop: any SyncEventLoopProtocol,
                preferencesManager: any PreferencesManagerProtocol,
                removeUserLocalData: any RemoveUserLocalDataUseCase,
                featureFlagsRepository: any FeatureFlagsRepositoryProtocol,
                passMonitorRepository: any PassMonitorRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol,
                vaultsManager: any VaultsManagerProtocol,
                apiManager: any APIManagerProtocol,
                authManager: any AuthManagerProtocol,
                credentialManager: any CredentialManagerProtocol,
                switchUser: any SwitchUserUseCase) {
        self.userManager = userManager
        self.syncEventLoop = syncEventLoop
        self.preferencesManager = preferencesManager
        self.removeUserLocalData = removeUserLocalData
        self.featureFlagsRepository = featureFlagsRepository
        self.passMonitorRepository = passMonitorRepository
        self.accessRepository = accessRepository
        self.vaultsManager = vaultsManager
        self.apiManager = apiManager
        self.authManager = authManager
        self.credentialManager = credentialManager
        self.switchUser = switchUser
    }

    /// Logs out the user linked to the userId and return a boolean indicating if it's the last user of not
    /// - Parameter userId: The id of the user to logout
    /// - Returns: A boolean indicating if this was the last account to show the login flow or not
    public func execute(userId: String) async throws -> Bool {
        let users = try await userManager.getAllUsers()
        guard let user = users.first(where: { $0.user.ID == userId }) else {
            throw PassError.userManager(.noUserDataFound)
        }

        syncEventLoop.stop()
        if users.count == 1 {
            // Scenario 1: Only 1 user
            try await signOutLastUser(user)
            return true
        } else {
            let isActive = userManager.currentActiveUser.value?.user.ID == userId
            isActive ? try await signOutActiveUser(user) : try await signOutInactiveUser(user)
            syncEventLoop.start()
            return false
        }
    }
}

private extension LogOutUser {
    /// Scenario 1: Only 1 user
    /// Do not care if the user is active or not
    /// Step 1: Revoke the session
    /// Step 2: Stop the event loop
    /// Step 3: Remove cached credentials
    /// Step 4: Remove all local data
    /// Step 5: Reset repositories' on-memory caches
    /// Step 6: Back to welcome screen
    func signOutLastUser(_ userData: UserData) async throws {
        syncEventLoop.reset()
        featureFlagsRepository.clearUserId()

        async let preferenceReset: Void = preferencesManager.reset()
        async let removeCredentials: Void = credentialManager.removeAllCredentials()
        async let cleanPassMonitor: Void = passMonitorRepository.reset()
        async let cleanVaultManager: Void = vaultsManager.reset()

        _ = try await (preferenceReset,
                       removeCredentials,
                       cleanPassMonitor,
                       cleanVaultManager)

        try await commonDeletionActions(userId: userData.user.ID)
        apiManager.reset()
    }

    /// Scenario 2: Sign out active user when multiple users
    /// Step 1: Revoke the session
    /// Step 2: Stop the event loop
    /// Step 3: Remove cached credentials
    /// Step 4: Remove all local data
    /// Step 5: Activate to the latest inactive user
    /// Step 6: Reinit event loop with the new user
    /// Step 7: Reload items
    func signOutActiveUser(_ userData: UserData) async throws {
        try await commonDeletionActions(userId: userData.user.ID)

        // When removing active user userManager switches automatically to a new active user if possible
        // We should now use the switch user use case to propagate the change of active user
        let newActiveUserId = try await userManager.getActiveUserId()
        try await switchUser(userId: newActiveUserId)
    }

    /// Sign out inactive user when multiple users
    /// Step 1: Revoke the session
    /// Step 2: Remove all local data
    /// Step 3: Remove cached credentials
    func signOutInactiveUser(_ userData: UserData) async throws {
        try await commonDeletionActions(userId: userData.user.ID)
    }

    func commonDeletionActions(userId: String) async throws {
        async let removeUser: Void = userManager.remove(userId: userId)
        async let removeUserData: Void = removeUserLocalData(userId: userId)
        _ = try await (removeUser, removeUserData)

        // Removes all flags linked to user account
        featureFlagsRepository.resetFlags(for: userId)
        authManager.removeCredentials(userId: userId)
        try await accessRepository.loadAccesses()
        DispatchQueue.main.async {
            UIPasteboard.general.items = []
        }
    }
}
