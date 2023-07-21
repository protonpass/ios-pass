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
import ProtonCore_Login
import ProtonCore_Services

/// Contain all repositories
final class SharedRepositoryContainer: SharedContainer, AutoRegistering {
    private let apiManager = resolve(\SharedToolingContainer.apiManager)
    private let logManager = resolve(\SharedToolingContainer.logManager)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let currentDateProvider = resolve(\SharedToolingContainer.currentDateProvider)

    static let shared = SharedRepositoryContainer()
    let manager = ContainerManager()

    private init() {}

    func autoRegister() {
        manager.defaultScope = .cached
    }
}

// MARK: Data

extension SharedRepositoryContainer {
    var container: Factory<NSPersistentContainer> {
        self { fatalError("container not registered") }
    }

    var symmetricKey: Factory<SymmetricKey> {
        self { fatalError("symmetricKey not registered") }
    }

    var userData: Factory<UserData> {
        self { fatalError("userData not registered") }
    }
}

// MARK: Repositories

extension SharedRepositoryContainer {
    private var apiService: APIService { apiManager.apiService }

    var aliasRepository: Factory<AliasRepositoryProtocol> {
        self {
            AliasRepository(remoteDatasouce: RemoteAliasDatasource(apiService: self.apiService))
        }
    }

    var shareKeyRepository: Factory<ShareKeyRepositoryProtocol> {
        self {
            ShareKeyRepository(localDatasource: LocalShareKeyDatasource(container: self.container()),
                               remoteDatasource: RemoteShareKeyDatasource(apiService: self.apiService),
                               logManager: self.logManager,
                               symmetricKey: self.symmetricKey(),
                               userData: self.userData())
        }
    }

    var shareEventIDRepository: Factory<ShareEventIDRepositoryProtocol> {
        self {
            ShareEventIDRepository(localDatasource: LocalShareEventIDDatasource(container: self.container()),
                                   remoteDatasource: RemoteShareEventIDDatasource(apiService: self.apiService),
                                   logManager: self.logManager)
        }
    }

    var passKeyManager: Factory<PassKeyManagerProtocol> {
        self {
            PassKeyManager(shareKeyRepository: self.shareKeyRepository(),
                           itemKeyDatasource: RemoteItemKeyDatasource(apiService: self.apiService),
                           logManager: self.logManager,
                           symmetricKey: self.symmetricKey())
        }
    }

    var itemRepository: Factory<ItemRepositoryProtocol> {
        self {
            ItemRepository(userData: self.userData(),
                           symmetricKey: self.symmetricKey(),
                           localDatasoure: LocalItemDatasource(container: self.container()),
                           remoteDatasource: RemoteItemRevisionDatasource(apiService: self.apiService),
                           shareEventIDRepository: self.shareEventIDRepository(),
                           passKeyManager: self.passKeyManager(),
                           logManager: self.logManager)
        }
    }

    var passPlanRepository: Factory<PassPlanRepositoryProtocol> {
        self {
            PassPlanRepository(localDatasource: LocalPassPlanDatasource(container: self.container()),
                               remoteDatasource: RemotePassPlanDatasource(apiService: self.apiService),
                               userId: self.userData().user.ID,
                               logManager: self.logManager)
        }
    }

    var shareRepository: Factory<ShareRepositoryProtocol> {
        self { ShareRepository(symmetricKey: self.symmetricKey(),
                               userData: self.userData(),
                               localDatasource: LocalShareDatasource(container: self.container()),
                               remoteDatasouce: RemoteShareDatasource(apiService: self.apiService),
                               passKeyManager: self.passKeyManager(),
                               logManager: self.logManager) }
    }

    var telemetryEventRepository: Factory<TelemetryEventRepositoryProtocol> {
        self {
            let localDatasource = LocalTelemetryEventDatasource(container: self.container())
            let remoteDatasource = RemoteTelemetryEventDatasource(apiService: self.apiService)
            let remoteUserSettingsDatasource = RemoteUserSettingsDatasource(apiService: self.apiService)
            let scheduler = TelemetryScheduler(currentDateProvider: self.currentDateProvider,
                                               thresholdProvider: self.preferences)
            return TelemetryEventRepository(localTelemetryEventDatasource: localDatasource,
                                            remoteTelemetryEventDatasource: remoteDatasource,
                                            remoteUserSettingsDatasource: remoteUserSettingsDatasource,
                                            passPlanRepository: self.passPlanRepository(),
                                            logManager: self.logManager,
                                            scheduler: scheduler,
                                            userId: self.userData().user.ID)
        }
    }

    var featureFlagsRepository: Factory<FeatureFlagsRepositoryProtocol> {
        self {
            FeatureFlagsRepository(localFeatureFlagsDatasource: LocalFeatureFlagsDatasource(container: self
                                       .container()),
            remoteFeatureFlagsDatasource: RemoteFeatureFlagsDatasource(apiService: self
                .apiService),
            userId: self.userData().user.ID,
            logManager: self.logManager)
        }
    }

    var favIconRepository: Factory<FavIconRepositoryProtocol> {
        self { FavIconRepository(datasource: RemoteFavIconDatasource(apiService: self.apiService),
                                 containerUrl: URL.favIconsContainerURL(),
                                 settings: self.preferences,
                                 symmetricKey: self.symmetricKey()) }
    }

    var credentialManager: Factory<CredentialManagerProtocol> {
        self { CredentialManager(logManager: self.logManager) }
    }

    var localSearchEntryDatasource: Factory<LocalSearchEntryDatasourceProtocol> {
        self { LocalSearchEntryDatasource(container: self.container()) }
    }

    var remoteSyncEventsDatasource: Factory<RemoteSyncEventsDatasourceProtocol> {
        self { RemoteSyncEventsDatasource(apiService: self.apiService) }
    }

    var upgradeChecker: ParameterFactory<LimitationCounterProtocol, UpgradeCheckerProtocol> {
        self { UpgradeChecker(passPlanRepository: self.passPlanRepository(),
                              counter: $0,
                              totpChecker: self.itemRepository()) }
    }
}
