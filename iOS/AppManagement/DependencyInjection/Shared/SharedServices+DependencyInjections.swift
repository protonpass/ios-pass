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
import DIComposition
import FactoryKit
@preconcurrency import ProtonCoreTelemetry
import Stores

final class OldSharedServiceContainer: SharedContainer, AutoRegistering {
    static let shared = OldSharedServiceContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .singleton
    }

    @MainActor
    var itemContextMenuHandler: Factory<ItemContextMenuHandler> {
        self { ItemContextMenuHandler() }
    }
}

//
// private extension ServiceContainer {
//    var logManager: any LogManagerProtocol {
//        ToolingContainer.shared.logManager()
//    }
//
//    var currentDateProvider: any CurrentDateProviderProtocol {
//        ToolingContainer.shared.currentDateProvider()
//    }
//
//    var shareRepository: any ShareRepositoryProtocol {
//        RepositoryContainer.shared.shareRepository()
//    }
//
//    var itemRepository: any ItemRepositoryProtocol {
//        RepositoryContainer.shared.itemRepository()
//    }
//
//    var accessRepository: any AccessRepositoryProtocol {
//        RepositoryContainer.shared.accessRepository()
//    }
// }
//
// extension ServiceContainer {
//    var notificationService: Factory<any LocalNotificationServiceProtocol> {
//        self { NotificationService(logManager: self.logManager) }
//    }
//
//    var dataMigrationManager: Factory<any DataMigrationManagerProtocol> {
//        self { DataMigrationManager(datasource: RepositoryContainer.shared.localDataMigrationDatasource()) }
//    }
//
//    var credentialManager: Factory<any CredentialManagerProtocol> {
//        self { CredentialManager(logManager: self.logManager) }
//    }
//
//    var eventSynchronizer: Factory<any EventSynchronizerProtocol> {
//        self { EventSynchronizer(shareRepository: self.shareRepository,
//                                 itemRepository: self.itemRepository,
//                                 shareKeyRepository: RepositoryContainer.shared.shareKeyRepository(),
//                                 shareEventIDRepository: RepositoryContainer.shared.shareEventIDRepository(),
//                                 remoteSyncEventsDatasource: RepositoryContainer.shared
//                                     .remoteSyncEventsDatasource(),
//                                 aliasRepository: RepositoryContainer.shared.aliasRepository(),
//                                 accessRepository: self.accessRepository,
//                                 userManager: self.userManager(),
//                                 logManager: self.logManager) }
//    }
//
//    var userEventsSynchronizer: Factory<any UserEventsSynchronizerProtocol> {
//        self {
//            let container = RepositoryContainer.shared
//            return UserEventsSynchronizer(localUserEventIdDatasource: container.localUserEventIdDatasource(),
//                                          remoteUserEventsDatasource: container.remoteUserEventsDatasource(),
//                                          itemRepository: container.itemRepository(),
//                                          shareRepository: container.shareRepository(),
//                                          accessRepository: container.accessRepository(),
//                                          inviteRepository: container.inviteRepository(),
//                                          folderRepository: container.folderRepository(),
//                                          aliasRepository: container.aliasRepository(),
//                                          passMonitorRepository: container.passMonitorRepository(),
//                                          organizationRepository: container.organizationRepository(),
//                                          simpleLoginNoteSynchronizer: self.simpleLoginNoteSynchronizer(),
//                                          logManager: self.logManager)
//        }
//    }
//
//    var coreEventsSynchronizer: Factory<any CoreEventsSynchronizerProtocol> {
//        self {
//            let container = RepositoryContainer.shared
//            return CoreEventsSynchronizer(localDatasource: container.localCoreEventIdDatasource(),
//                                          remoteDatasource: container.remoteCoreEventIdDatasource(),
//                                          remoteUserDataSource: container.remoteUserDataDatasource(),
//                                          userManager: self.userManager(),
//                                          logManager: self.logManager)
//        }
//    }
//
//    var syncEventLoop: Factory<SyncEventLoop> {
//        self { SyncEventLoop(currentDateProvider: self.currentDateProvider,
//                             synchronizer: self.eventSynchronizer(),
//                             userEventsSynchronizer: self.userEventsSynchronizer(),
//                             coreEventsSynchronizer: self.coreEventsSynchronizer(),
//                             userManager: self.userManager(),
//                             logManager: self.logManager,
//                             reachability: ServiceContainer.shared.reachabilityService()) }
//    }
//
//    var simpleLoginNoteSynchronizer: Factory<any SimpleLoginNoteSynchronizerProtocol> {
//        self {
//            SimpleLoginNoteSynchronizer(remoteDatasource: RepositoryContainer.shared.remoteAliasDatasource(),
//                                        itemRepository: self.itemRepository)
//        }
//    }
//

// }
//
//    @MainActor
//    var appContentManager: Factory<AppContentManager> {
//        self { AppContentManager(itemRepository: self.itemRepository,
//                                 shareRepository: self.shareRepository,
//                                 inviteRepository: RepositoryContainer.shared.inviteRepository(),
//                                 folderRepository: RepositoryContainer.shared.folderRepository(),
//                                 slNoteSynchronizer: ServiceContainer.shared.simpleLoginNoteSynchronizer(),
//                                 preferencesManager: ToolingContainer.shared.preferencesManager(),
//                                 symmetricKeyProvider: DataContainer.shared.symmetricKeyProvider(),
//                                 indexAllLoginItems: SharedUseCasesContainer.shared.indexAllLoginItems(),
//                                 indexItemsForSpotlight: SharedUseCasesContainer.shared.indexItemsForSpotlight(),
//                                 deleteLocalDataBeforeFullSync: SharedUseCasesContainer.shared
//                                     .deleteLocalDataBeforeFullSync(),
//                                 getLastEventIdIfNotExist: SharedUseCasesContainer.shared
//                                     .getLastEventIdIfNotExist(),
//                                 getFeatureFlagStatus: SharedUseCasesContainer.shared.getFeatureFlagStatus(),
//                                 dedupShare: SharedUseCasesContainer.shared.dedupShare(),
//                                 refreshUserData: SharedUseCasesContainer.shared.refreshUserData(),
//                                 logger: ToolingContainer.shared.logger(),
//                                 loginMethod: DataContainer.shared.loginMethod()) }
//    }
//
//    @MainActor
//    var upgradeChecker: Factory<any UpgradeCheckerProtocol> {
//        self { UpgradeChecker(accessRepository: RepositoryContainer.shared.accessRepository(),
//                              counter: self.appContentManager(),
//                              totpChecker: RepositoryContainer.shared.itemRepository()) }
//    }
//
//    var databaseService: Factory<any DatabaseServiceProtocol> {
//        self { DatabaseService(logManager: self.logManager) }
//    }
//
//    var reachabilityService: Factory<any ReachabilityServicing> {
//        self { ReachabilityService() }
//    }
//
//    var userDefaultService: Factory<any UserDefaultPersistency> {
//        self { UserDefaultService(appGroup: Constants.appGroup) }
//    }
//
//    var totpService: Factory<any TOTPServiceProtocol> {
//        self { TOTPService(currentDateProvider: self.currentDateProvider) }
//    }
//
//    var totpManager: Factory<any TOTPManagerProtocol> {
//        self { TOTPManager(logManager: self.logManager,
//                           totpService: self.totpService()) }
//            .unique
//    }
//
//    var cachedFavIconsManager: Factory<any CachedFavIconsManagerProtocol> {
//        self { CachedFavIconsManager() }
//    }
//
//    var inAppNotificationManager: Factory<any InAppNotificationManagerProtocol> {
//        self {
//            let container = RepositoryContainer.shared
//            return InAppNotificationManager(repository: container.inAppNotificationRepository(),
//                                            timeDatasource: container.localNotificationTimeDatasource(),
//                                            userManager: self.userManager(),
//                                            logManager: self.logManager)
//        }
//    }
//
//    var telemetryService: Factory<any TelemetryServiceProtocol> {
//        self { TelemetryService.shared }
//    }
//
//    // periphery:ignore
//    var abTestingManager: Factory<any ABTestingManagerProtocol> {
//        self { ABTestingManager() }
//    }
//
//    var featureDiscoveryManager: Factory<any FeatureDiscoveryManagerProtocol> {
//        self { FeatureDiscoveryManager(storage: kSharedUserDefaults,
//                                       accessRepository: self.accessRepository,
//                                       logManager: self.logManager) }
//    }
//
//    var cryptoService: Factory<any CryptoServiceProtocol> {
//        self {
//            CryptoService(remoteDatasource: RepositoryContainer.shared.remoteShareDatasource(),
//                          localDatasource: RepositoryContainer.shared.localShareDatasource(),
//                          groupRepository: RepositoryContainer.shared.groupRepository(),
//                          logManager: self.logManager,
//                          publicKeyRepository: RepositoryContainer.shared.publicKeyRepository(),
//                          symmetricKeyProvider: DataContainer.shared.symmetricKeyProvider(),
//                          userManager: self.userManager())
//        }
//    }
// }
//
//// MARK: - User
//
// extension ServiceContainer {
//    var userManager: Factory<any UserManagerProtocol> {
//        self {
//            UserManager(userDataDatasource: RepositoryContainer.shared.localUserDataDatasource(),
//                        logManager: self.logManager)
//        }
//    }
// }
