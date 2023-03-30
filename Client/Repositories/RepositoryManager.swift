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

    private let apiService: APIService
    private let container: NSPersistentContainer
    private let logManager: LogManager
    private let symmetricKey: SymmetricKey
    private let userData: UserData

    public init(apiService: APIService,
                container: NSPersistentContainer,
                logManager: LogManager,
                symmetricKey: SymmetricKey,
                userData: UserData) {
        self.apiService = apiService
        self.container = container
        self.logManager = logManager
        self.symmetricKey = symmetricKey
        self.userData = userData
    }

    // Repositories
    public lazy var aliasRepository = makeAliasRepository()
    public lazy var itemRepository = makeItemRepository()
    public lazy var passKeyManager = makePassKeyManager()
    public lazy var shareEventIDRepository = makeShareEventIDRepository()
    public lazy var shareRepository = makeShareRespository()
    public lazy var shareKeyRepository = makeShareKeyRepository()

    // Public datasources
    public lazy var localSearchEntryDatasource = makeLocalSearchEntryDatasource()
    public lazy var remoteSyncEventsDatasource = makeRemoteSyncEventsDatasource()

    // Private datasources
    private lazy var remoteAliasDatasource = makeRemoteAliasDatasource()

    private lazy var localItemDatasource = makeLocalItemDatasource()
    private lazy var remoteItemDatasource = makeRemoteItemDatasource()

    private lazy var localShareDatasource = makeLocalShareDatasource()
    private lazy var remoteShareDatasource = makeRemoteShareDatasource()

    private lazy var localShareKeyDatasource = makeLocalShareKeyDatasource()
    private lazy var remoteShareKeyDatasource = makeRemoteShareKeyDatasource()

    private lazy var remoteItemKeyDatasource = makeRemoteItemKeyDatasource()

    private lazy var localShareEventIDDatasource = makeLocalShareEventIDDatasource()
    private lazy var remoteShareEventIDDatasource = makeRemoteShareEventIDDatasource()
}

// MARK: - Make repositories
private extension RepositoryManager {
    func makeAliasRepository() -> AliasRepositoryProtocol {
        AliasRepository(remoteAliasDatasouce: remoteAliasDatasource)
    }

    func makeItemRepository() -> ItemRepositoryProtocol {
        ItemRepository(userData: userData,
                       symmetricKey: symmetricKey,
                       localItemDatasoure: localItemDatasource,
                       remoteItemRevisionDatasource: remoteItemDatasource,
                       shareRepository: shareRepository,
                       shareEventIDRepository: shareEventIDRepository,
                       passKeyManager: passKeyManager,
                       logManager: logManager)
    }

    func makePassKeyManager() -> PassKeyManagerProtocol {
        PassKeyManager(userData: userData,
                       shareKeyRepository: shareKeyRepository,
                       itemKeyDatasource: remoteItemKeyDatasource,
                       logManager: logManager)
    }

    func makeShareRespository() -> ShareRepositoryProtocol {
        ShareRepository(userData: userData,
                        localShareDatasource: localShareDatasource,
                        remoteShareDatasouce: remoteShareDatasource,
                        passKeyManager: passKeyManager,
                        logManager: logManager)
    }

    func makeShareEventIDRepository() -> ShareEventIDRepositoryProtocol {
        ShareEventIDRepository(
            localShareEventIDDatasource: localShareEventIDDatasource,
            remoteShareEventIDDatasource: remoteShareEventIDDatasource,
            logManager: logManager)
    }

    func makeShareKeyRepository() -> ShareKeyRepositoryProtocol {
        ShareKeyRepository(localShareKeyDatasource: localShareKeyDatasource,
                           remoteShareKeyDatasource: remoteShareKeyDatasource,
                           logManager: logManager,
                           userData: userData)
    }
}

// MARK: - Make datasources
private extension RepositoryManager {
    func makeRemoteAliasDatasource() -> RemoteAliasDatasourceProtocol {
        RemoteAliasDatasource(apiService: apiService)
    }

    func makeLocalItemDatasource() -> LocalItemDatasourceProtocol {
        LocalItemDatasource(container: container)
    }

    func makeRemoteItemDatasource() -> RemoteItemRevisionDatasourceProtocol {
        RemoteItemRevisionDatasource(apiService: apiService)
    }

    func makeLocalShareDatasource() -> LocalShareDatasourceProtocol {
        LocalShareDatasource(container: container)
    }

    func makeRemoteShareDatasource() -> RemoteShareDatasourceProtocol {
        RemoteShareDatasource(apiService: apiService)
    }

    func makeLocalShareKeyDatasource() -> LocalShareKeyDatasourceProtocol {
        LocalShareKeyDatasource(container: container)
    }

    func makeRemoteShareKeyDatasource() -> RemoteShareKeyDatasourceProtocol {
        RemoteShareKeyDatasource(apiService: apiService)
    }

    func makeRemoteItemKeyDatasource() -> RemoteItemKeyDatasourceProtocol {
        RemoteItemKeyDatasource(apiService: apiService)
    }

    func makeLocalShareEventIDDatasource() -> LocalShareEventIDDatasourceProtocol {
        LocalShareEventIDDatasource(container: container)
    }

    func makeRemoteShareEventIDDatasource() -> RemoteShareEventIDDatasourceProtocol {
        RemoteShareEventIDDatasource(apiService: apiService)
    }

    func makeLocalSearchEntryDatasource() -> LocalSearchEntryDatasourceProtocol {
        LocalSearchEntryDatasource(container: container)
    }

    func makeRemoteSyncEventsDatasource() -> RemoteSyncEventsDatasourceProtocol {
        RemoteSyncEventsDatasource(apiService: apiService)
    }
}
