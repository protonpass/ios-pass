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

    func reset() {
        manager.reset()
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
        SharedDataContainer.shared.fullDataProvider()
    }
}

// MARK: Repositories

extension SharedRepositoryContainer {
    var aliasRepository: Factory<AliasRepositoryProtocol> {
        self {
            AliasRepository(remoteDatasouce: RemoteAliasDatasource(apiService: self.apiService))
        }
    }

    var shareKeyRepository: Factory<ShareKeyRepositoryProtocol> {
        self {
            ShareKeyRepository(localDatasource: LocalShareKeyDatasource(databaseService: self.databaseService),
                               remoteDatasource: RemoteShareKeyDatasource(apiService: self.apiService),
                               logManager: self.logManager,
                               userDataSymmetricKeyProvider: self.userDataSymmetricKeyProvider)
        }
    }

    var shareEventIDRepository: Factory<ShareEventIDRepositoryProtocol> {
        self {
            ShareEventIDRepository(localDatasource: LocalShareEventIDDatasource(databaseService: self
                                       .databaseService),
            remoteDatasource: RemoteShareEventIDDatasource(apiService: self.apiService),
            logManager: self.logManager)
        }
    }

    var passKeyManager: Factory<PassKeyManagerProtocol> {
        self {
            PassKeyManager(shareKeyRepository: self.shareKeyRepository(),
                           itemKeyDatasource: RemoteItemKeyDatasource(apiService: self.apiService),
                           logManager: self.logManager,
                           symmetricKeyProvider: self.symmetricKeyProvider)
        }
    }

    var itemRepository: Factory<ItemRepositoryProtocol> {
        self {
            ItemRepository(userDataSymmetricKeyProvider: self.userDataSymmetricKeyProvider,
                           localDatasource: LocalItemDatasource(databaseService: self.databaseService),
                           remoteDatasource: RemoteItemRevisionDatasource(apiService: self.apiService),
                           shareEventIDRepository: self.shareEventIDRepository(),
                           passKeyManager: self.passKeyManager(),
                           logManager: self.logManager)
        }
    }

    var accessRepository: Factory<AccessRepositoryProtocol> {
        self {
            AccessRepository(localDatasource: LocalAccessDatasource(databaseService: self.databaseService),
                             remoteDatasource: RemoteAccessDatasource(apiService: self.apiService),
                             userDataProvider: self.userDataProvider,
                             logManager: self.logManager)
        }
    }

    var shareRepository: Factory<ShareRepositoryProtocol> {
        self { ShareRepository(userDataSymmetricKeyProvider: self.userDataSymmetricKeyProvider,
                               localDatasource: LocalShareDatasource(databaseService: self.databaseService),
                               remoteDatasouce: RemoteShareDatasource(apiService: self.apiService),
                               passKeyManager: self.passKeyManager(),
                               logManager: self.logManager) }
    }

    var publicKeyRepository: Factory<PublicKeyRepositoryProtocol> {
        self {
            PublicKeyRepository(localPublicKeyDatasource: LocalPublicKeyDatasource(databaseService: self
                                    .databaseService),
            remotePublicKeyDatasource: RemotePublicKeyDatasource(apiService: self
                .apiService),
            logManager: self.logManager)
        }
    }

    var shareInviteRepository: Factory<ShareInviteRepositoryProtocol> {
        self { ShareInviteRepository(remoteDataSource: RemoteShareInviteDatasource(apiService: self.apiService),
                                     logManager: self.logManager) }
    }

    var telemetryEventRepository: Factory<TelemetryEventRepositoryProtocol> {
        self {
            // swiftformat:disable:next all
            TelemetryEventRepository(
                localDatasource: LocalTelemetryEventDatasource(databaseService: self.databaseService),
                remoteDatasource: RemoteTelemetryEventDatasource(apiService: self.apiService),
                remoteUserSettingsDatasource: RemoteUserSettingsDatasource(apiService: self
                    .apiService),
                accessRepository: self.accessRepository(),
                logManager: self.logManager,
                scheduler: TelemetryScheduler(currentDateProvider: self.currentDateProvider,
                                              thresholdProvider: self.preferences),
                userDataProvider: self.userDataProvider)
        }
    }

    var featureFlagsRepository: Factory<FeatureFlagsRepositoryProtocol> {
        self {
            FeatureFlagsRepository(configuration: FeatureFlagsConfiguration(userId: SharedDataContainer.shared
                                       .userDataProvider().getUserData()?.user.ID ?? "",
                currentBUFlags: FeatureFlagType.self),
            localDatasource: LocalFeatureFlagsDatasource(databaseService: self.databaseService),
            remoteDatasource: DefaultRemoteDatasource(apiService: self.apiService))
        }
    }

    var favIconRepository: Factory<FavIconRepositoryProtocol> {
        self { FavIconRepository(datasource: RemoteFavIconDatasource(apiService: self.apiService),
                                 containerUrl: URL.favIconsContainerURL(),
                                 settings: self.preferences,
                                 symmetricKeyProvider: self.symmetricKeyProvider) }
    }

    var localSearchEntryDatasource: Factory<LocalSearchEntryDatasourceProtocol> {
        self { LocalSearchEntryDatasource(databaseService: self.databaseService) }
    }

    var remoteSyncEventsDatasource: Factory<RemoteSyncEventsDatasourceProtocol> {
        self { RemoteSyncEventsDatasource(apiService: self.apiService) }
    }
}
