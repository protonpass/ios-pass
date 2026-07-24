//
// ItemRepositoryTests.swift
// Proton Pass - Created on 01/12/2023.
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

@testable import Client
import ClientMocks
import Combine
import Core
import CoreMocks
import Entities
import ProtonCoreLogin
import Testing
import Foundation

@Suite(.tags(.repository))
struct ItemRepositoryTests {
    private let symmetricKeyProvider: SymmetricKeyProviderMock
    private let userManager: UserManagerProtocolMock
    private let localDatasource: LocalItemDatasourceProtocolMock
    private let remoteDatasource: RemoteItemDatasourceProtocolMock
    private let localShareDatasource: LocalShareDatasourceProtocolMock
    private let shareEventIDRepository: ShareEventIDRepositoryProtocolMock
    private let passKeyManager: PassKeyManagerProtocolMock
    private let logManager: LogManagerProtocolMock

    init() {
        symmetricKeyProvider = SymmetricKeyProviderMock()
        userManager = UserManagerProtocolMock()
        localDatasource = LocalItemDatasourceProtocolMock()
        localDatasource.stubbedGetAllPinnedItemsResult = []
        remoteDatasource = RemoteItemDatasourceProtocolMock()
        localShareDatasource = LocalShareDatasourceProtocolMock()
        shareEventIDRepository = ShareEventIDRepositoryProtocolMock()
        passKeyManager = PassKeyManagerProtocolMock()
        logManager = LogManagerProtocolMock()
    }
}

// MARK: - Pinned tests

extension ItemRepositoryTests {
    @Test("Get all pinned items", .timeLimit(.minutes(1)))
    func getAllPinnedItems() async throws {
        let user = UserData.preview
        let shareId = UUID().uuidString
        localShareDatasource.stubbedGetAllSharesUserIdAsyncResult2 =
            [SymmetricallyEncryptedShare(encryptedContent: nil,
                                         share: .random(shareId: shareId))]
        localDatasource.stubbedGetAllPinnedItemsResult =
            [SymmetricallyEncryptedItem].random(count: 10,
                                                randomElement: .random(shareId: shareId,
                                                                       userId: user.user.ID,
                                                                       item: .random(pinned: true)))
        userManager.stubbedGetActiveUserDataResult = user

        let sut = ItemRepository(symmetricKeyProvider: symmetricKeyProvider,
                                 userManager: userManager,
                                 localDatasource: localDatasource,
                                 remoteDatasource: remoteDatasource,
                                 localShareDatasource: localShareDatasource,
                                 shareEventIDRepository: shareEventIDRepository,
                                 passKeyManager: passKeyManager,
                                 logManager: logManager)

        let pinnedItems = try await sut.getAllPinnedItems()
        #expect(pinnedItems.count == 10)

        var loaded: [SymmetricallyEncryptedItem]?
        for await value in sut.currentlyPinnedItems.values {
            if let value {
                loaded = value
                break
            }
        }

        let items = try #require(loaded)
        #expect(items.count == 10)
        #expect(localDatasource.invokedGetAllPinnedItemsfunction)
  
        #expect(localDatasource.invokedGetAllPinnedItemsCount == 2)
    }
}
