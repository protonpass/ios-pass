//
// WipeAllData.swift
// Proton Pass - Created on 14/11/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Client
import Core
import Foundation
import ProtonCoreFeatureFlags
import UIKit

protocol WipeAllDataUseCase: Sendable {
    func execute() async
}

extension WipeAllDataUseCase {
    func callAsFunction() async {
        await execute()
    }
}

final class WipeAllData: WipeAllDataUseCase {
    private let logger: Logger
    private let appData: any AppDataProtocol
    private let apiManager: APIManager
    private let preferencesManager: any PreferencesManagerProtocol
    private let databaseService: any DatabaseServiceProtocol
    private let syncEventLoop: any SyncEventLoopProtocol
    private let vaultsManager: VaultsManager
    private let vaultSyncEventStream: VaultSyncEventStream
    private let credentialManager: any CredentialManagerProtocol
    private let userManager: any UserManagerProtocol
    private let featureFlagsRepository: any FeatureFlagsRepositoryProtocol
    private let passMonitorRepository: any PassMonitorRepositoryProtocol

    init(logManager: any LogManagerProtocol,
         appData: any AppDataProtocol,
         apiManager: APIManager,
         preferencesManager: any PreferencesManagerProtocol,
         databaseService: any DatabaseServiceProtocol,
         syncEventLoop: any SyncEventLoopProtocol,
         vaultsManager: VaultsManager,
         vaultSyncEventStream: VaultSyncEventStream,
         credentialManager: any CredentialManagerProtocol,
         userManager: any UserManagerProtocol,
         featureFlagsRepository: any FeatureFlagsRepositoryProtocol,
         passMonitorRepository: any PassMonitorRepositoryProtocol) {
        logger = .init(manager: logManager)
        self.appData = appData
        self.apiManager = apiManager
        self.preferencesManager = preferencesManager
        self.databaseService = databaseService
        self.syncEventLoop = syncEventLoop
        self.vaultsManager = vaultsManager
        self.vaultSyncEventStream = vaultSyncEventStream
        self.credentialManager = credentialManager
        self.userManager = userManager
        self.featureFlagsRepository = featureFlagsRepository
        self.passMonitorRepository = passMonitorRepository
    }

    // Order matters because we remove data base on current user ID
    // so we shouldn't remove current user ID before removing data
    func execute() async {
        logger.info("Wiping all data")

        try? await preferencesManager.reset()
        if let userID = try? await userManager.getActiveUserId(), !userID.isEmpty {
            featureFlagsRepository.resetFlags(for: userID)
        }
        featureFlagsRepository.clearUserId()

        await passMonitorRepository.reset()
        appData.resetData()
        // swiftlint:disable:next todo
        // TODO: need to move this in session manager
        apiManager.clearCredentials()
        databaseService.resetContainer()

        UIPasteboard.general.items = []

        // swiftlint:disable:next todo
        // TODO: only kill sync if last account being logged out
        syncEventLoop.reset()

        // swiftlint:disable:next todo
        // TODO: only reset if last account being logged out but should
        await vaultsManager.reset()
        vaultSyncEventStream.value = .initialization

        if let userId = try? await userManager.getActiveUserId() {
            try? await userManager.remove(userId: userId)
        }
        // swiftlint:disable:next todo
        // TODO: should be handle by auth/session manager
        try? await credentialManager.removeAllCredentials()
        logger.info("Wiped all data")
    }
}
