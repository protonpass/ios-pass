//
// SharedServices+DependencyInjections.swift
// Proton Pass - Created on 06/06/2023.
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
import Factory

final class SharedServiceContainer: SharedContainer, AutoRegistering {
    static let shared = SharedServiceContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

private extension SharedServiceContainer {
    var logManager: LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }
}

extension SharedServiceContainer {
    var notificationService: Factory<LocalNotificationServiceProtocol> {
        self { NotificationService(logManager: self.logManager) }
    }

    var credentialManager: Factory<CredentialManagerProtocol> {
        self { CredentialManager(logManager: self.logManager) }
    }

    var syncEventLoop: Factory<SyncEventLoop> {
        self {
            .init(currentDateProvider: SharedToolingContainer.shared.currentDateProvider(),
                  userDataProvider: SharedDataContainer.shared.userDataProvider(),
                  shareRepository: SharedRepositoryContainer.shared.shareRepository(),
                  shareEventIDRepository: SharedRepositoryContainer.shared.shareEventIDRepository(),
                  remoteSyncEventsDatasource: SharedRepositoryContainer.shared.remoteSyncEventsDatasource(),
                  itemRepository: SharedRepositoryContainer.shared.itemRepository(),
                  shareKeyRepository: SharedRepositoryContainer.shared.shareKeyRepository(),
                  logManager: self.logManager)
        }
    }

    var clipboardManager: Factory<ClipboardManager> {
        self { ClipboardManager(bannerManager: SharedViewContainer.shared.bannerManager(),
                                preferences: SharedToolingContainer.shared.preferences()) }
    }

    var itemContextMenuHandler: Factory<ItemContextMenuHandler> {
        self { ItemContextMenuHandler() }
    }

    var vaultsManager: Factory<VaultsManager> {
        self { VaultsManager() }
    }

    var vaultSyncEventStream: Factory<VaultSyncEventStream> {
        self { VaultSyncEventStream(.initialization) }
    }

    var upgradeChecker: Factory<UpgradeCheckerProtocol> {
        self { UpgradeChecker(accessRepository: SharedRepositoryContainer.shared.accessRepository(),
                              counter: self.vaultsManager(),
                              totpChecker: SharedRepositoryContainer.shared.itemRepository()) }
    }

    var databaseService: Factory<DatabaseServiceProtocol> {
        self { DatabaseService(logManager: self.logManager) }
    }
}
