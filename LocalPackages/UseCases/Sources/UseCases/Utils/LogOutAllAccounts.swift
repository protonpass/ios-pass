//
//
// LogOutAllAccounts.swift
// Proton Pass - Created on 25/07/2024.
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
import Core
@preconcurrency import ProtonCoreFeatureFlags
import ProtonCoreLogin
import UIKit

public protocol LogOutAllAccountsUseCase: Sendable {
    func execute() async throws
}

public extension LogOutAllAccountsUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class LogOutAllAccounts: LogOutAllAccountsUseCase {
    private let userManager: any UserManagerProtocol
    private let syncEventLoop: any SyncEventLoopProtocol
    private let preferencesManager: any PreferencesManagerProtocol
    private let removeUserLocalData: any RemoveUserLocalDataUseCase
    private let featureFlagsRepository: any FeatureFlagsRepositoryProtocol
    private let passMonitorRepository: any PassMonitorRepositoryProtocol
    private let appContentManager: any AppContentManagerProtocol
    private let apiManager: any APIManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let credentialManager: any CredentialManagerProtocol
    private let keychain: any KeychainProtocol

    public init(userManager: any UserManagerProtocol,
                syncEventLoop: any SyncEventLoopProtocol,
                preferencesManager: any PreferencesManagerProtocol,
                removeUserLocalData: any RemoveUserLocalDataUseCase,
                featureFlagsRepository: any FeatureFlagsRepositoryProtocol,
                passMonitorRepository: any PassMonitorRepositoryProtocol,
                appContentManager: any AppContentManagerProtocol,
                apiManager: any APIManagerProtocol,
                authManager: any AuthManagerProtocol,
                credentialManager: any CredentialManagerProtocol,
                keychain: any KeychainProtocol) {
        self.userManager = userManager
        self.syncEventLoop = syncEventLoop
        self.preferencesManager = preferencesManager
        self.removeUserLocalData = removeUserLocalData
        self.featureFlagsRepository = featureFlagsRepository
        self.passMonitorRepository = passMonitorRepository
        self.appContentManager = appContentManager
        self.apiManager = apiManager
        self.authManager = authManager
        self.credentialManager = credentialManager
        self.keychain = keychain
    }

    public func execute() async throws {
        syncEventLoop.stop()
        syncEventLoop.reset()
        featureFlagsRepository.clearUserId()

        for userData in userManager.allUserAccounts.value {
            try await removeUserLocalData(userId: userData.user.ID)
        }

        async let preferenceReset: Void = preferencesManager.resetAll()
        async let removeCredentials: Void = credentialManager.removeAllCredentials()
        async let cleanPassMonitor: Void = passMonitorRepository.reset()
        async let cleanAppContentManager: Void = appContentManager.reset()
        async let userManagerReset: Void = userManager.cleanAllUsers()

        _ = try await (preferenceReset,
                       removeCredentials,
                       cleanPassMonitor,
                       cleanAppContentManager,
                       userManagerReset)

        // Removes all flags linked to user account
        featureFlagsRepository.resetFlags()
        authManager.removeAllCredentials()
        DispatchQueue.main.async {
            UIPasteboard.general.items = []
        }

        try keychain.removeOrError(forKey: Constants.biometricStateKey)
    }
}
