//
//
// SwitchUser.swift
// Proton Pass - Created on 09/07/2024.
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

public protocol SwitchUserUseCase: Sendable {
    func execute(userId: String) async throws
}

public extension SwitchUserUseCase {
    func callAsFunction(userId: String) async throws {
        try await execute(userId: userId)
    }
}

public final class SwitchUser: SwitchUserUseCase {
    private let userManager: any UserManagerProtocol
    private let vaultsManager: any VaultsManagerProtocol
    private let preferencesManager: any PreferencesManagerProtocol
    private let apiManager: any APIManagerProtocol
    private let syncEventLoop: any SyncEventLoopProtocol
    private let refreshFeatureFlags: any RefreshFeatureFlagsUseCase

    public init(userManager: any UserManagerProtocol,
                vaultsManager: any VaultsManagerProtocol,
                preferencesManager: any PreferencesManagerProtocol,
                apiManager: any APIManagerProtocol,
                syncEventLoop: any SyncEventLoopProtocol,
                refreshFeatureFlags: any RefreshFeatureFlagsUseCase) {
        self.userManager = userManager
        self.vaultsManager = vaultsManager
        self.preferencesManager = preferencesManager
        self.apiManager = apiManager
        self.syncEventLoop = syncEventLoop
        self.refreshFeatureFlags = refreshFeatureFlags
    }

    public func execute(userId: String) async throws {
        syncEventLoop.stop()
        try await preferencesManager.switchUserPreferences(userId: userId)
        try await userManager.switchActiveUser(with: userId)
        try await vaultsManager.localFullSync(userId: userId)
        refreshFeatureFlags()
        syncEventLoop.start()
    }
}
