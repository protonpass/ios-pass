//
//
// AddAndSwitchToNewUserAccount.swift
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
import ProtonCoreLogin

public protocol AddAndSwitchToNewUserAccountUseCase: Sendable {
    func execute(userData: UserData, hasExtraPassword: Bool) async throws
}

public extension AddAndSwitchToNewUserAccountUseCase {
    func callAsFunction(userData: UserData, hasExtraPassword: Bool) async throws {
        try await execute(userData: userData, hasExtraPassword: hasExtraPassword)
    }
}

public final class AddAndSwitchToNewUserAccount: AddAndSwitchToNewUserAccountUseCase {
    private let syncEventLoop: any SyncEventLoopProtocol
    private let userManager: any UserManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let preferencesManager: any PreferencesManagerProtocol
    private let apiManager: any APIManagerProtocol
    private let fullVaultsSync: any FullVaultsSyncUseCase
    private let refreshFeatureFlags: any RefreshFeatureFlagsUseCase
    private let inviteRepository: any InviteRepositoryProtocol

    public init(syncEventLoop: any SyncEventLoopProtocol,
                userManager: any UserManagerProtocol,
                authManager: any AuthManagerProtocol,
                preferencesManager: any PreferencesManagerProtocol,
                apiManager: any APIManagerProtocol,
                fullVaultsSync: any FullVaultsSyncUseCase,
                refreshFeatureFlags: any RefreshFeatureFlagsUseCase,
                inviteRepository: any InviteRepositoryProtocol) {
        self.syncEventLoop = syncEventLoop
        self.userManager = userManager
        self.authManager = authManager
        self.preferencesManager = preferencesManager
        self.apiManager = apiManager
        self.fullVaultsSync = fullVaultsSync
        self.refreshFeatureFlags = refreshFeatureFlags
        self.inviteRepository = inviteRepository
    }

    public func execute(userData: UserData, hasExtraPassword: Bool) async throws {
        syncEventLoop.stop()
        // We add the new user and credential to the user manager and the main authManager
        // We also update the main apiservice with the new session id through apiManager
        try await userManager.upsertAndMarkAsActive(userData: userData)
        try await preferencesManager.switchUserPreferences(userId: userData.user.ID)
        refreshFeatureFlags()
        if hasExtraPassword {
            try await preferencesManager.updateUserPreferences(\.extraPasswordEnabled,
                                                               value: true)
        }
        await fullVaultsSync(userId: userData.user.ID)
        await inviteRepository.refreshInvites()
        syncEventLoop.start()
    }
}
