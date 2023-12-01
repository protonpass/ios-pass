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
import ProtonCoreServices
import XCTest

final class ItemRepositoryTests: XCTestCase {
    var userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider!
    var localDatasource: LocalItemDatasourceProtocol!
    var remoteDatasource: RemoteItemDatasourceProtocol!
    var shareEventIDRepository: ShareEventIDRepositoryProtocol!
    var passKeyManager: PassKeyManagerProtocol!
    var logManager: LogManagerProtocol!
    var sut: ItemRepositoryProtocol!

    override func setUp() {
        super.setUp()
         userDataSymmetricKeyProvider = UserDataSymmetricKeyProviderMock()
         localDatasource = LocalItemDatasourceProtocolMock()
         (localDatasource as? LocalItemDatasourceProtocolMock)?.stubbedGetAllPinnedItemsResult = []
         remoteDatasource = RemoteItemDatasourceProtocolMock()
         shareEventIDRepository = ShareEventIDRepositoryProtocolMock()
         passKeyManager = PassKeyManagerProtocolMock()
         logManager = LogManagerProtocolMock()
    }

    override func tearDown() {
        userDataSymmetricKeyProvider = nil
        localDatasource = nil
        remoteDatasource = nil
        shareEventIDRepository = nil
        passKeyManager = nil
        logManager = nil
        sut = nil
        super.tearDown()
    }
}

//public init(userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider,
//            localDatasource: LocalItemDatasourceProtocol,
//            remoteDatasource: RemoteItemDatasourceProtocol,
//            shareEventIDRepository: ShareEventIDRepositoryProtocol,
//            passKeyManager: PassKeyManagerProtocol,
//            logManager: LogManagerProtocol)


//public actor ItemRepository: ItemRepositoryProtocol {
//    private let userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider
//    private let localDatasource: LocalItemDatasourceProtocol
//    private let remoteDatasource: RemoteItemDatasourceProtocol
//    private let shareEventIDRepository: ShareEventIDRepositoryProtocol
//    private let passKeyManager: PassKeyManagerProtocol
//    private let logger: Logger
//
//    public let currentlyPinnedItems: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never> = .init(nil)
//
//    public init(userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider,
//                localDatasource: LocalItemDatasourceProtocol,
//                remoteDatasource: RemoteItemDatasourceProtocol,
//                shareEventIDRepository: ShareEventIDRepositoryProtocol,
//                passKeyManager: PassKeyManagerProtocol,
//                logManager: LogManagerProtocol) {
//        self.userDataSymmetricKeyProvider = userDataSymmetricKeyProvider
//        self.localDatasource = localDatasource
//        self.remoteDatasource = remoteDatasource
//        self.shareEventIDRepository = shareEventIDRepository
//        self.passKeyManager = passKeyManager
//        logger = .init(manager: logManager)
//        Task { [weak self] in
//            let pinnedItems = try? await self?.localDatasource.getAllPinnedItems()
//            self?.currentlyPinnedItems.send(pinnedItems)
//        }
//    }
//}

// MARK: - Pinned tests

extension ItemRepositoryTests {
    
    func testPinnedItem() async throws {
        // Given
//        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
//                                                    thresholdProvider: thresholdProvider)
        
        sut = ItemRepository(userDataSymmetricKeyProvider: userDataSymmetricKeyProvider,
                             localDatasource: localDatasource,
                             remoteDatasource: remoteDatasource,
                             shareEventIDRepository: shareEventIDRepository,
                             passKeyManager: passKeyManager,
                             logManager: logManager)
        
        let pinnedItems = try await sut.getAllPinnedItems()
        XCTAssertTrue(pinnedItems.isEmpty)
//
//        // When
//        let sendResult = try await sut.sendAllEventsIfApplicable()
//
//        // Then
//        XCTAssertNotNil(sut.scheduler.threshhold)
//        XCTAssertEqual(sendResult, .thresholdNotReached)
    }

}
