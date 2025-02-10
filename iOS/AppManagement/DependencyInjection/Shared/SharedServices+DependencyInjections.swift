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
@preconcurrency import ProtonCoreTelemetry

final class SharedServiceContainer: SharedContainer, AutoRegistering {
    static let shared = SharedServiceContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

private extension SharedServiceContainer {
    var logManager: any LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }

    var currentDateProvider: any CurrentDateProviderProtocol {
        SharedToolingContainer.shared.currentDateProvider()
    }

    var shareRepository: any ShareRepositoryProtocol {
        SharedRepositoryContainer.shared.shareRepository()
    }

    var itemRepository: any ItemRepositoryProtocol {
        SharedRepositoryContainer.shared.itemRepository()
    }
}

extension SharedServiceContainer {
    var notificationService: Factory<any LocalNotificationServiceProtocol> {
        self { NotificationService(logManager: self.logManager) }
    }

    var dataMigrationManager: Factory<any DataMigrationManagerProtocol> {
        self { DataMigrationManager(datasource: SharedRepositoryContainer.shared.localDataMigrationDatasource()) }
    }

    var credentialManager: Factory<any CredentialManagerProtocol> {
        self { CredentialManager(logManager: self.logManager) }
    }

    var eventSynchronizer: Factory<any EventSynchronizerProtocol> {
        self { EventSynchronizer(shareRepository: self.shareRepository,
                                 itemRepository: self.itemRepository,
                                 shareKeyRepository: SharedRepositoryContainer.shared.shareKeyRepository(),
                                 shareEventIDRepository: SharedRepositoryContainer.shared.shareEventIDRepository(),
                                 remoteSyncEventsDatasource: SharedRepositoryContainer.shared
                                     .remoteSyncEventsDatasource(),
                                 aliasRepository: SharedRepositoryContainer.shared.aliasRepository(),
                                 accessRepository: SharedRepositoryContainer.shared.accessRepository(),
                                 userManager: self.userManager(),
                                 logManager: self.logManager,
                                 featureFlagsRepository: SharedRepositoryContainer.shared
                                     .featureFlagsRepository()) }
    }

    var syncEventLoop: Factory<SyncEventLoop> {
        self { SyncEventLoop(currentDateProvider: self.currentDateProvider,
                             synchronizer: self.eventSynchronizer(),
                             userManager: self.userManager(),
                             logManager: self.logManager,
                             reachability: SharedServiceContainer.shared.reachabilityService()) }
    }

    var itemContextMenuHandler: Factory<ItemContextMenuHandler> {
        self { ItemContextMenuHandler() }
    }

    var appContentManager: Factory<AppContentManager> {
        self { AppContentManager() }
    }

    var upgradeChecker: Factory<any UpgradeCheckerProtocol> {
        self { UpgradeChecker(accessRepository: SharedRepositoryContainer.shared.accessRepository(),
                              counter: self.appContentManager(),
                              totpChecker: SharedRepositoryContainer.shared.itemRepository()) }
    }

    var databaseService: Factory<any DatabaseServiceProtocol> {
        self { DatabaseService(logManager: self.logManager) }
    }

    var reachabilityService: Factory<any ReachabilityServicing> {
        self { ReachabilityService() }
    }

    var userDefaultService: Factory<any UserDefaultPersistency> {
        self { UserDefaultService(appGroup: Constants.appGroup) }
    }

    var totpService: Factory<any TOTPServiceProtocol> {
        self { TOTPService(currentDateProvider: self.currentDateProvider) }
    }

    var totpManager: Factory<any TOTPManagerProtocol> {
        self { TOTPManager(logManager: self.logManager,
                           totpService: self.totpService()) }
            .unique
    }

    var cachedFavIconsManager: Factory<any CachedFavIconsManagerProtocol> {
        self { CachedFavIconsManager() }
    }

    var inAppNotificationManager: Factory<any InAppNotificationManagerProtocol> {
        self {
            let container = SharedRepositoryContainer.shared
            return InAppNotificationManager(repository: container.inAppNotificationRepository(),
                                            timeDatasource: container.localNotificationTimeDatasource(),
                                            userManager: self.userManager(),
                                            logManager: self.logManager)
        }
    }

    var telemetryService: Factory<any TelemetryServiceProtocol> {
        self { TelemetryService.shared }
    }

    var abTestingManager: Factory<any ABTestingManagerProtocol> {
        self { ABTestingManager() }
    }

    // swiftlint:disable:next todo
    // TODO: transform vault Manager
//    var appContentManager: Factory<any AppContentManagerServicing> {
//        self { AppContentManager(userManager: self.userManager(),
//                                 itemRepository: self.itemRepository,
//                                 shareRepository: self.shareRepository,
//                                 logManager: self.logManager)
//        }
//    }
}

// MARK: - User

extension SharedServiceContainer {
    var userManager: Factory<any UserManagerProtocol> {
        self {
            UserManager(userDataDatasource: SharedRepositoryContainer.shared.localUserDataDatasource(),
                        logManager: self.logManager)
        }
    }
}
