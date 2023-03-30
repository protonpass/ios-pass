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
    public let shareEventIDRepository: ShareEventIDRepositoryProtocol
    public let shareRepository: ShareRepositoryProtocol
    public let shareKeyRepository: ShareKeyRepositoryProtocol

    public let localSearchEntryDatasource: LocalSearchEntryDatasourceProtocol
    public let remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol

    public init(apiService: APIService,
                container: NSPersistentContainer,
                logManager: LogManager,
                symmetricKey: SymmetricKey,
                userData: UserData) {
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

        let shareKeyRepository = ShareKeyRepository(localShareKeyDatasource: localShareKeyDatasource,
                                                    remoteShareKeyDatasource: remoteShareKeyDatasource,
                                                    logManager: logManager,
                                                    userData: userData)

        let passKeyManager = PassKeyManager(userData: userData,
                                            shareKeyRepository: shareKeyRepository,
                                            itemKeyDatasource: remoteItemKeyDatasource,
                                            logManager: logManager)

        let shareEventIDRepository = ShareEventIDRepository(
            localShareEventIDDatasource: localShareEventIDDatasource,
            remoteShareEventIDDatasource: remoteShareEventIDDatasource,
            logManager: logManager)

        let shareRepository = ShareRepository(userData: userData,
                                              localShareDatasource: localShareDatasource,
                                              remoteShareDatasouce: remoteShareDatasource,
                                              passKeyManager: passKeyManager,
                                              logManager: logManager)

        self.aliasRepository = AliasRepository(remoteAliasDatasouce: remoteAliasDatasource)
        self.itemRepository = ItemRepository(userData: userData,
                                             symmetricKey: symmetricKey,
                                             localItemDatasoure: localItemDatasource,
                                             remoteItemRevisionDatasource: remoteItemDatasource,
                                             shareRepository: shareRepository,
                                             shareEventIDRepository: shareEventIDRepository,
                                             passKeyManager: passKeyManager,
                                             logManager: logManager)
        self.passKeyManager = passKeyManager
        self.shareEventIDRepository = shareEventIDRepository
        self.shareRepository = shareRepository
        self.shareKeyRepository = shareKeyRepository

        self.localSearchEntryDatasource = LocalSearchEntryDatasource(container: container)
        self.remoteSyncEventsDatasource = RemoteSyncEventsDatasource(apiService: apiService)
    }
}
