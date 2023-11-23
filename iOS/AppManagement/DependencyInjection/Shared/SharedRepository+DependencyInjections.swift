//
// SharedRepository+DependencyInjections.swift
// Proton Pass - Created on 21/07/2023.
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
import CoreData
import CryptoKit
import Factory
import ProtonCoreLogin
import ProtonCoreServices

/// Contain all repositories
final class SharedRepositoryContainer: SharedContainer, AutoRegistering {
    static let shared = SharedRepositoryContainer()
    let manager = ContainerManager()

    private init() {}

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

// MARK: - Computed properties

private extension SharedRepositoryContainer {
    var apiManager: APIManager {
        SharedToolingContainer.shared.apiManager()
    }

    var apiService: APIService {
        apiManager.apiService
    }

    var logManager: LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }

    var preferences: Preferences {
        SharedToolingContainer.shared.preferences()
    }

    var currentDateProvider: CurrentDateProviderProtocol {
        SharedToolingContainer.shared.currentDateProvider()
    }

    var databaseService: DatabaseServiceProtocol {
        SharedServiceContainer.shared.databaseService()
    }

    var userDataProvider: UserDataProvider {
        SharedDataContainer.shared.userDataProvider()
    }

    var symmetricKeyProvider: SymmetricKeyProvider {
        SharedDataContainer.shared.symmetricKeyProvider()
    }

    var userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider {
        SharedDataContainer.shared.appData()
    }

    var corruptedSessionEventStream: CorruptedSessionEventStream {
        SharedDataStreamContainer.shared.corruptedSessionEventStream()
    }
}

// MARK: Datasources

private extension SharedRepositoryContainer {
    var remoteAliasDatasource: Factory<RemoteAliasDatasourceProtocol> {
        self { RemoteAliasDatasource(apiService: self.apiService,
                                     eventStream: self.corruptedSessionEventStream) }
    }

    var localShareKeyDatasource: Factory<LocalShareKeyDatasourceProtocol> {
        self { LocalShareKeyDatasource(databaseService: self.databaseService) }
    }

    var remoteShareKeyDatasource: Factory<RemoteShareKeyDatasourceProtocol> {
        self { RemoteShareKeyDatasource(apiService: self.apiService,
                                        eventStream: self.corruptedSessionEventStream) }
    }

    var localShareEventIDDatasource: Factory<LocalShareEventIDDatasourceProtocol> {
        self { LocalShareEventIDDatasource(databaseService: self.databaseService) }
    }

    var remoteShareEventIDDatasource: Factory<RemoteShareEventIDDatasourceProtocol> {
        self { RemoteShareEventIDDatasource(apiService: self.apiService,
                                            eventStream: self.corruptedSessionEventStream) }
    }

    var remoteItemKeyDatasource: Factory<RemoteItemKeyDatasourceProtocol> {
        self { RemoteItemKeyDatasource(apiService: self.apiService,
                                       eventStream: self.corruptedSessionEventStream) }
    }

    var localItemDatasource: Factory<LocalItemDatasourceProtocol> {
        self { LocalItemDatasource(databaseService: self.databaseService) }
    }

    var remoteItemDatasource: Factory<RemoteItemRevisionDatasourceProtocol> {
        self { RemoteItemRevisionDatasource(apiService: self.apiService,
                                            eventStream: self.corruptedSessionEventStream) }
    }

    var localAccessDatasource: Factory<LocalAccessDatasourceProtocol> {
        self { LocalAccessDatasource(databaseService: self.databaseService) }
    }

    var remoteAccessDatasource: Factory<RemoteAccessDatasourceProtocol> {
        self { RemoteAccessDatasource(apiService: self.apiService,
                                      eventStream: self.corruptedSessionEventStream) }
    }

    var localShareDatasource: Factory<LocalShareDatasourceProtocol> {
        self { LocalShareDatasource(databaseService: self.databaseService) }
    }

    var remoteShareDatasource: Factory<RemoteShareDatasourceProtocol> {
        self { RemoteShareDatasource(apiService: self.apiService,
                                     eventStream: self.corruptedSessionEventStream) }
    }

    var localPublicKeyDatasource: Factory<LocalPublicKeyDatasourceProtocol> {
        self { LocalPublicKeyDatasource(databaseService: self.databaseService) }
    }

    var remotePublicKeyDatasource: Factory<RemotePublicKeyDatasourceProtocol> {
        self { RemotePublicKeyDatasource(apiService: self.apiService) }
    }

    var remoteShareInviteDatasource: Factory<RemoteShareInviteDatasourceProtocol> {
        self { RemoteShareInviteDatasource(apiService: self.apiService,
                                           eventStream: self.corruptedSessionEventStream) }
    }

    var localTelemetryEventDatasource: Factory<LocalTelemetryEventDatasourceProtocol> {
        self { LocalTelemetryEventDatasource(databaseService: self.databaseService) }
    }

    var remoteTelemetryEventDatasource: Factory<RemoteTelemetryEventDatasourceProtocol> {
        self { RemoteTelemetryEventDatasource(apiService: self.apiService,
                                              eventStream: self.corruptedSessionEventStream) }
    }

    var remoteUserSettingsDatasource: Factory<RemoteUserSettingsDatasourceProtocol> {
        self { RemoteUserSettingsDatasource(apiService: self.apiService,
                                            eventStream: self.corruptedSessionEventStream) }
    }

    var telemetryScheduler: Factory<TelemetrySchedulerProtocol> {
        self { TelemetryScheduler(currentDateProvider: self.currentDateProvider,
                                  thresholdProvider: self.preferences) }
    }

    var featureFlagsConfiguration: Factory<FeatureFlagsConfiguration> {
        self { FeatureFlagsConfiguration(userId: self.userDataProvider.getUserData()?.user.ID ?? "",
                                         currentBUFlags: FeatureFlagType.self) }
    }

    var localFeatureFlagsDatasource: Factory<LocalFeatureFlagsProtocol> {
        self { LocalFeatureFlagsDatasource(databaseService: self.databaseService) }
    }

    var remoteFeatureFlagsDatasource: Factory<RemoteFeatureFlagsProtocol> {
        self { DefaultRemoteDatasource(apiService: self.apiService) }
    }

    var remoteFavIconDatasource: Factory<RemoteFavIconDatasourceProtocol> {
        self { RemoteFavIconDatasource(apiService: self.apiService,
                                       eventStream: self.corruptedSessionEventStream) }
    }
}

// MARK: Repositories

extension SharedRepositoryContainer {
    var aliasRepository: Factory<AliasRepositoryProtocol> {
        self { AliasRepository(remoteDatasouce: self.remoteAliasDatasource()) }
    }

    var shareKeyRepository: Factory<ShareKeyRepositoryProtocol> {
        self {
            ShareKeyRepository(localDatasource: self.localShareKeyDatasource(),
                               remoteDatasource: self.remoteShareKeyDatasource(),
                               logManager: self.logManager,
                               userDataSymmetricKeyProvider: self.userDataSymmetricKeyProvider)
        }
    }

    var shareEventIDRepository: Factory<ShareEventIDRepositoryProtocol> {
        self {
            ShareEventIDRepository(localDatasource: self.localShareEventIDDatasource(),
                                   remoteDatasource: self.remoteShareEventIDDatasource(),
                                   logManager: self.logManager)
        }
    }

    var passKeyManager: Factory<PassKeyManagerProtocol> {
        self {
            PassKeyManager(shareKeyRepository: self.shareKeyRepository(),
                           itemKeyDatasource: self.remoteItemKeyDatasource(),
                           logManager: self.logManager,
                           symmetricKeyProvider: self.symmetricKeyProvider)
        }
    }

    var itemRepository: Factory<ItemRepositoryProtocol> {
        self {
            ItemRepository(userDataSymmetricKeyProvider: self.userDataSymmetricKeyProvider,
                           localDatasource: self.localItemDatasource(),
                           remoteDatasource: self.remoteItemDatasource(),
                           shareEventIDRepository: self.shareEventIDRepository(),
                           passKeyManager: self.passKeyManager(),
                           logManager: self.logManager)
        }
    }

    var accessRepository: Factory<AccessRepositoryProtocol> {
        self {
            AccessRepository(localDatasource: self.localAccessDatasource(),
                             remoteDatasource: self.remoteAccessDatasource(),
                             userDataProvider: self.userDataProvider,
                             logManager: self.logManager)
        }
    }

    var shareRepository: Factory<ShareRepositoryProtocol> {
        self { ShareRepository(userDataSymmetricKeyProvider: self.userDataSymmetricKeyProvider,
                               localDatasource: self.localShareDatasource(),
                               remoteDatasouce: self.remoteShareDatasource(),
                               passKeyManager: self.passKeyManager(),
                               logManager: self.logManager) }
    }

    var publicKeyRepository: Factory<PublicKeyRepositoryProtocol> {
        self {
            PublicKeyRepository(localPublicKeyDatasource: self.localPublicKeyDatasource(),
                                remotePublicKeyDatasource: self.remotePublicKeyDatasource(),
                                logManager: self.logManager)
        }
    }

    var shareInviteRepository: Factory<ShareInviteRepositoryProtocol> {
        self { ShareInviteRepository(remoteDataSource: self.remoteShareInviteDatasource(),
                                     logManager: self.logManager) }
    }

    var telemetryEventRepository: Factory<TelemetryEventRepositoryProtocol> {
        self {
            TelemetryEventRepository(localDatasource: self.localTelemetryEventDatasource(),
                                     remoteDatasource: self.remoteTelemetryEventDatasource(),
                                     remoteUserSettingsDatasource: self.remoteUserSettingsDatasource(),
                                     accessRepository: self.accessRepository(),
                                     logManager: self.logManager,
                                     scheduler: self.telemetryScheduler(),
                                     userDataProvider: self.userDataProvider)
        }
    }

    var featureFlagsRepository: Factory<FeatureFlagsRepositoryProtocol> {
        self {
            FeatureFlagsRepository(configuration: self.featureFlagsConfiguration(),
                                   localDatasource: self.localFeatureFlagsDatasource(),
                                   remoteDatasource: self.remoteFeatureFlagsDatasource())
        }
    }

    var favIconRepository: Factory<FavIconRepositoryProtocol> {
        self { FavIconRepository(datasource: self.remoteFavIconDatasource(),
                                 containerUrl: URL.favIconsContainerURL(),
                                 settings: self.preferences,
                                 symmetricKeyProvider: self.symmetricKeyProvider) }
    }

    var localSearchEntryDatasource: Factory<LocalSearchEntryDatasourceProtocol> {
        self { LocalSearchEntryDatasource(databaseService: self.databaseService) }
    }

    var remoteSyncEventsDatasource: Factory<RemoteSyncEventsDatasourceProtocol> {
        self { RemoteSyncEventsDatasource(apiService: self.apiService,
                                          eventStream: self.corruptedSessionEventStream) }
    }
}
