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
import ProtonCoreFeatureFlags
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
        self.vaultsManager = vaultsManager
        self.apiManager = apiManager
        self.authManager = authManager
        self.credentialManager = credentialManager
        self.switchUser = switchUser
    }

    /// Logs out the user linked to the userId and return a boolean indicating if it's the last user of not
    /// - Parameter userId: The id of the user to logout
    /// - Returns: A boolean indicating if this was the last account link to the meaning we should show login flow
    /// or not log screens
    public func execute(userId: String) async throws -> Bool {
        let users = try await userManager.getAllUsers()
        guard let user = users.first(where: { $0.user.ID == userId }) else {
            throw PassError.userManager(.noUserDataFound)
        }

        let isActive = userManager.currentActiveUser.value?.user.ID == userId
        let isLastUserAccount = users.count == 1

        syncEventLoop.stop()
        // Scenario 1: Only 1 user
        if isLastUserAccount {
            try await signOutLastUserAccount(user)
            return true
        } else {
            isActive ? try await signOutActiveUser(userData: user) : try await signOutInactive(user)
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
    func signOutLastUserAccount(_ userData: UserData) async throws {
        syncEventLoop.reset()
        try await preferencesManager.reset()

        try await commonDeletionActions(userId: userData.user.ID)

        // Clean current active user id in feature flag repo
        featureFlagsRepository.clearUserId()
        await passMonitorRepository.reset()
        await vaultsManager.reset()
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
    func signOutActiveUser(userData: UserData) async throws {
        try await commonDeletionActions(userId: userData.user.ID)

        // When removing active user userManager switches automatically to a new active user if possible
        //  We should now user the switch user use case to propagate the cahnge of active user
        let newActiveUserId = try await userManager.getActiveUserId()
        try await switchUser(userId: newActiveUserId)
    }

    /// Sign out inactive user when multiple users
    /// Step 1: Revoke the session
    /// Step 2: Remove all local data
    /// Step 3: Remove cached credentials
    func signOutInactive(_ userData: UserData) async throws {
        try await commonDeletionActions(userId: userData.user.ID)
    }

    // TODO: Need to optimise and do work in parralle
    func commonDeletionActions(userId: String) async throws {
        try await userManager.remove(userId: userId)
        // Removes all data linked to user account
        try await removeUserLocalData(userId: userId)
        // Removes all flags linked to user account
        featureFlagsRepository.resetFlags(for: userId)
        authManager.removeCredentials(userId: userId)
        try await credentialManager.removeAllCredentials()
        DispatchQueue.main.async {
            UIPasteboard.general.items = []
        }
    }
}

//
// import Client
// import Core
// import Foundation
// import ProtonCoreFeatureFlags
// import UIKit
// import UseCases
//
// protocol WipeAllDataUseCase: Sendable {
//    // swiftlint:disable:next todo
//    // TODO: Remove the dependance on `UserManagerProtocol` and inject `userId`
//    func execute() async
// }
//
// extension WipeAllDataUseCase {
//    func callAsFunction() async {
//        await execute()
//    }
// }
//
// final class WipeAllData: WipeAllDataUseCase {
//    private let logger: Logger
//    private let appData: any AppDataProtocol
//    private let apiManager: APIManager
//    private let preferencesManager: any PreferencesManagerProtocol
//    private let syncEventLoop: any SyncEventLoopProtocol
//    private let vaultsManager: VaultsManager
//    private let vaultSyncEventStream: VaultSyncEventStream
//    private let credentialManager: any CredentialManagerProtocol
//    private let userManager: any UserManagerProtocol
//    private let featureFlagsRepository: any FeatureFlagsRepositoryProtocol
//    private let passMonitorRepository: any PassMonitorRepositoryProtocol
//    private let removeUserLocalData: any RemoveUserLocalDataUseCase
//
//    init(logManager: any LogManagerProtocol,
//         appData: any AppDataProtocol,
//         apiManager: APIManager,
//         preferencesManager: any PreferencesManagerProtocol,
//         syncEventLoop: any SyncEventLoopProtocol,
//         vaultsManager: VaultsManager,
//         vaultSyncEventStream: VaultSyncEventStream,
//         credentialManager: any CredentialManagerProtocol,
//         userManager: any UserManagerProtocol,
//         featureFlagsRepository: any FeatureFlagsRepositoryProtocol,
//         passMonitorRepository: any PassMonitorRepositoryProtocol,
//         removeUserLocalData: any RemoveUserLocalDataUseCase) {
//        logger = .init(manager: logManager)
//        self.appData = appData
//        self.apiManager = apiManager
//        self.preferencesManager = preferencesManager
//        self.syncEventLoop = syncEventLoop
//        self.vaultsManager = vaultsManager
//        self.vaultSyncEventStream = vaultSyncEventStream
//        self.credentialManager = credentialManager
//        self.userManager = userManager
//        self.featureFlagsRepository = featureFlagsRepository
//        self.passMonitorRepository = passMonitorRepository
//        self.removeUserLocalData = removeUserLocalData
//    }
//
//    // Order matters because we remove data base on current user ID
//    // so we shouldn't remove current user ID before removing data
//    func execute() async {
//        logger.info("Wiping all data")
//
//        try? await preferencesManager.reset()
//        if let userID = try? await userManager.getActiveUserId(), !userID.isEmpty {
//            featureFlagsRepository.resetFlags(for: userID)
//            try? await removeUserLocalData(userId: userID)
//        }
//
//        await passMonitorRepository.reset()
//        //This should be done at the migration
//        appData.resetData()
//        // swiftlint:disable:next todo
//        // TODO: need to move this in session manager
////        apiManager.clearCredentials()
//
//        UIPasteboard.general.items = []
//
//        // swiftlint:disable:next todo
//        // TODO: only kill sync if last account being logged out
//        syncEventLoop.reset()
//
//        // swiftlint:disable:next todo
//        // TODO: only reset if last account being logged out but should
//        await vaultsManager.reset()
//        vaultSyncEventStream.value = .initialization
//
//        if let userId = try? await userManager.getActiveUserId() {
//            try? await userManager.remove(userId: userId)
//        }
//        // swiftlint:disable:next todo
//        // TODO: should be handle by auth/session manager
//        try? await credentialManager.removeAllCredentials()
//        logger.info("Wiped all data")
//    }
// }
//
//
// RemoveUserLocalDataUseCase
//
// extension HomepageCoordinator {
//    func handleSignOut(userId: String) {
//        Task { [weak self] in
//            guard let self else { return }
//            do {
//                let users = try await userManager.getAllUsers()
//                guard let user = users.first(where: { $0.user.ID == userId }) else {
//                    throw PassError.userManager(.noUserDataFound)
//                }
//
//                let isActive = userManager.currentActiveUser.value?.user.ID == userId
//                let multiAccounts = users.count > 1
//
//                // Scenario 1: Only 1 user
//                if !multiAccounts {
//                    signOutSingleUser(user)
//                    return
//                }
//
//                // Scenario 2: Sign out active user when multiple users
//                if isActive {
//                    try signOutActiveUser(userToSignOut: user, allUsers: users)
//                    return
//                }
//
//                // Scenario 3: Sign out inactive user when multiple users
//                if !isActive {
//                    signOutInactive(user)
//                    return
//                }
//
//                assertionFailure("Not known sign out scenario")
//            } catch {
//                handle(error: error)
//            }
//        }
//    }
//
//    func wipeAllDataAndSignoutActiveUser() {
//        Task { [weak self] in
//            guard let self else { return }
//            await wipeAllData()
//            eventLoop.stop()
//            delegate?.homepageCoordinatorWantsToLogOut()
//        }
//    }
// }
//
// private extension HomepageCoordinator {
//
//
//    /// Scenario 2: Sign out active user when multiple users
//    /// Step 1: Revoke the session
//    /// Step 2: Stop the event loop
//    /// Step 3: Remove cached credentials
//    /// Step 4: Remove all local data
//    /// Step 5: Activate to the latest inactive user
//    /// Step 6: Reinit event loop with the new user
//    /// Step 7: Reload items
//    func signOutActiveUser(userToSignOut: UserData, allUsers: [UserData]) throws {
//        let otherUsers = allUsers.filter { $0.user.ID != userToSignOut.user.ID }
//        guard let accountToActivate = otherUsers.first else {
//            throw PassError.userManager(.noInactiveUserFound)
//        }
//        let alert = signOutAlert(accountToSignOut: userToSignOut,
//                                 accountToActivate: accountToActivate,
//                                 onSignOut: { print(#function) })
//        present(alert)
//    }
//
//    /// Sign out inactive user when multiple users
//    /// Step 1: Revoke the session
//    /// Step 2: Remove all local data
//    /// Step 3: Remove cached credentials
//    func signOutInactive(_ userData: UserData) {
//        let alert = signOutAlert(accountToSignOut: userData,
//                                 accountToActivate: nil,
//                                 onSignOut: { print(#function) })
//        present(alert)
//    }
//
//    func signOutAlert(accountToSignOut: UserData,
//                      accountToActivate: UserData?,
//                      onSignOut: @escaping () -> Void) -> UIAlertController {
//        let signOut = #localized("Sign out")
//        let message = if let accountToActivate {
//            #localized("You will be switched to %@", accountToActivate.user.email ?? "")
//        } else {
//            #localized("Are you sure you want to sign out %@?", accountToSignOut.user.email ?? "")
//        }
//        // Show as alert on iPad because action sheets on iPad are considered a popover
//        // which requires additional set up otherwise it will crash
//        let alert = UIAlertController(title: signOut,
//                                      message: message,
//                                      preferredStyle: UIDevice.current.isIpad ? .alert : .actionSheet)
//        alert.addAction(.init(title: signOut,
//                              style: .destructive,
//                              handler: { _ in onSignOut() }))
//        alert.addAction(.init(title: #localized("Cancel"), style: .cancel))
//        return alert
//    }
// }
