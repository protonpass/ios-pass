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

    var eventSynchronizer: Factory<EventSynchronizerProtocol> {
        self { EventSynchronizer(shareRepository: SharedRepositoryContainer.shared.shareRepository(),
                                 itemRepository: SharedRepositoryContainer.shared.itemRepository(),
                                 shareKeyRepository: SharedRepositoryContainer.shared.shareKeyRepository(),
                                 shareEventIDRepository: SharedRepositoryContainer.shared.shareEventIDRepository(),
                                 remoteSyncEventsDatasource: SharedRepositoryContainer.shared
                                     .remoteSyncEventsDatasource(),
                                 userDataProvider: SharedDataContainer.shared.userDataProvider(),
                                 logManager: self.logManager) }
    }

    var syncEventLoop: Factory<SyncEventLoop> {
        self { SyncEventLoop(currentDateProvider: SharedToolingContainer.shared.currentDateProvider(),
                             synchronizer: self.eventSynchronizer(),
                             logManager: self.logManager,
                             reachability: SharedServiceContainer.shared.reachabilityService()) }
    }

    var clipboardManager: Factory<ClipboardManagerProtocol> {
        self { ClipboardManager(bannerManager: SharedViewContainer.shared.bannerManager(),
                                preferences: SharedToolingContainer.shared.preferences()) }
    }

    @MainActor
    var itemContextMenuHandler: Factory<ItemContextMenuHandler> {
        self { ItemContextMenuHandler() }
    }

    var vaultsManager: Factory<VaultsManager> {
        self { VaultsManager() }
    }

    var upgradeChecker: Factory<UpgradeCheckerProtocol> {
        self { UpgradeChecker(accessRepository: SharedRepositoryContainer.shared.accessRepository(),
                              counter: self.vaultsManager(),
                              totpChecker: SharedRepositoryContainer.shared.itemRepository()) }
    }

    var databaseService: Factory<DatabaseServiceProtocol> {
        self { DatabaseService(logManager: self.logManager) }
    }

    var reachabilityService: Factory<ReachabilityServicing> {
        self { ReachabilityService() }
    }

    var userDefaultService: Factory<UserDefaultPersistency> {
        self { UserDefaultService(appGroup: Constants.appGroup) }
    }
}
