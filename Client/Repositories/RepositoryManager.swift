//
// RepositoryManager.swift
// Proton Pass - Created on 30/03/2023.
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

import Core
import CoreData
import CryptoKit
import ProtonCore_Login
import ProtonCore_Services

public final class RepositoryManager: DeinitPrintable {
    deinit { print(deinitMessage) }

    public let aliasRepository: AliasRepositoryProtocol
    public let itemRepository: ItemRepositoryProtocol
    public let passKeyManager: PassKeyManagerProtocol
    public let passPlanRepository: PassPlanRepositoryProtocol
    public let shareEventIDRepository: ShareEventIDRepositoryProtocol
    public let shareRepository: ShareRepositoryProtocol
    public let shareKeyRepository: ShareKeyRepositoryProtocol
    public let telemetryEventRepository: TelemetryEventRepositoryProtocol
    public let featureFlagsRepository: FeatureFlagsRepositoryProtocol

    public let localSearchEntryDatasource: LocalSearchEntryDatasourceProtocol
    public let remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol

    public let upgradeChecker: UpgradeCheckerProtocol

    public init(apiService: APIService,
                container: NSPersistentContainer,
                currentDateProvider: CurrentDateProviderProtocol,
                limitationCounter: LimitationCounterProtocol,
                logManager: LogManagerProtocol,
                symmetricKey: SymmetricKey,
                userData: UserData,
                telemetryThresholdProvider: TelemetryThresholdProviderProtocol) {
        let remoteAliasDatasource = RemoteAliasDatasource(apiService: apiService)
        let localItemDatasource = LocalItemDatasource(container: container)

        let remoteItemDatasource = RemoteItemRevisionDatasource(apiService: apiService)
        let localShareDatasource = LocalShareDatasource(container: container)

        let remoteShareDatasource = RemoteShareDatasource(apiService: apiService)
        let localShareKeyDatasource = LocalShareKeyDatasource(container: container)

        let remoteShareKeyDatasource = RemoteShareKeyDatasource(apiService: apiService)
        let remoteItemKeyDatasource = RemoteItemKeyDatasource(apiService: apiService)
        let localShareEventIDDatasource = LocalShareEventIDDatasource(container: container)
        let remoteShareEventIDDatasource = RemoteShareEventIDDatasource(apiService: apiService)

        let remotePassPlanDatasource = RemotePassPlanDatasource(apiService: apiService)
        let localPassPlanDatasource = LocalPassPlanDatasource(container: container)

        let remoteTelemetryEventDatasource = RemoteTelemetryEventDatasource(apiService: apiService)
        let localTelemetryEventDatasource = LocalTelemetryEventDatasource(container: container)

        let passPlanRepository = PassPlanRepository(localDatasource: localPassPlanDatasource,
                                                    remoteDatasource: remotePassPlanDatasource,
                                                    userId: userData.user.ID,
                                                    logManager: logManager)

        let shareKeyRepository = ShareKeyRepository(localDatasource: localShareKeyDatasource,
                                                    remoteDatasource: remoteShareKeyDatasource,
                                                    logManager: logManager,
                                                    symmetricKey: symmetricKey,
                                                    userData: userData)

        let passKeyManager = PassKeyManager(shareKeyRepository: shareKeyRepository,
                                            itemKeyDatasource: remoteItemKeyDatasource,
                                            logManager: logManager,
                                            symmetricKey: symmetricKey)

        let shareEventIDRepository =
            ShareEventIDRepository(localDatasource: localShareEventIDDatasource,
                                   remoteDatasource: remoteShareEventIDDatasource,
                                   logManager: logManager)

        let shareRepository = ShareRepository(symmetricKey: symmetricKey,
                                              userData: userData,
                                              localDatasource: localShareDatasource,
                                              remoteDatasouce: remoteShareDatasource,
                                              passKeyManager: passKeyManager,
                                              logManager: logManager)

        let telemetryScheduler = TelemetryScheduler(currentDateProvider: currentDateProvider,
                                                    thresholdProvider: telemetryThresholdProvider)

        let remoteUserSettingsDatasource = RemoteUserSettingsDatasource(apiService: apiService)

        let userId = userData.user.ID

        aliasRepository = AliasRepository(remoteDatasouce: remoteAliasDatasource)
        itemRepository = ItemRepository(userData: userData,
                                        symmetricKey: symmetricKey,
                                        localDatasoure: localItemDatasource,
                                        remoteDatasource: remoteItemDatasource,
                                        shareEventIDRepository: shareEventIDRepository,
                                        passKeyManager: passKeyManager,
                                        logManager: logManager)
        self.passKeyManager = passKeyManager
        self.passPlanRepository = passPlanRepository
        self.shareEventIDRepository = shareEventIDRepository
        self.shareRepository = shareRepository
        self.shareKeyRepository = shareKeyRepository
        telemetryEventRepository =
            TelemetryEventRepository(localDatasource: localTelemetryEventDatasource,
                                     remoteDatasource: remoteTelemetryEventDatasource,
                                     remoteUserSettingsDatasource: remoteUserSettingsDatasource,
                                     passPlanRepository: passPlanRepository,
                                     logManager: logManager,
                                     scheduler: telemetryScheduler,
                                     userId: userId)
        featureFlagsRepository =
            FeatureFlagsRepository(localDatasource: LocalFeatureFlagsDatasource(container: container),
                                   remoteDatasource: RemoteFeatureFlagsDatasource(apiService: apiService),
                                   userId: userId,
                                   logManager: logManager)

        localSearchEntryDatasource = LocalSearchEntryDatasource(container: container)
        remoteSyncEventsDatasource = RemoteSyncEventsDatasource(apiService: apiService)

        upgradeChecker = UpgradeChecker(passPlanRepository: passPlanRepository,
                                        counter: limitationCounter,
                                        totpChecker: itemRepository)
    }
}
