//
// ShareRepositoryTests.swift
// Proton Pass - Created on 28/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import Core
import CoreMocks
import Combine
import Testing
import Entities
import EntitiesMocks

@Suite(.tags(.repository))
struct ShareRepositoryTests {
    private let symmetricKeyProvider: SymmetricKeyProviderMock
    private let userManager: UserManagerProtocolMock
    private let logManager: LogManagerProtocol
    private let passKeyManagerMock: PassKeyManagerProtocolMock
    private let localDatasourceMock: LocalShareDatasourceProtocolMock
    private let remoteDatasourceMock: RemoteShareDatasourceProtocolMock
    private let sut: ShareRepository

    init() {
        localDatasourceMock = LocalShareDatasourceProtocolMock()
        remoteDatasourceMock = RemoteShareDatasourceProtocolMock()
        userManager = UserManagerProtocolMock()
        symmetricKeyProvider = SymmetricKeyProviderMock()
        logManager = LogManagerProtocolMock()
        passKeyManagerMock = PassKeyManagerProtocolMock()
        
        sut = ShareRepository(
            symmetricKeyProvider: symmetricKeyProvider,
            userManager: userManager,
            localDatasource: localDatasourceMock,
            remoteDatasource: remoteDatasourceMock,
            passKeyManager: passKeyManagerMock,
            logManager: logManager
        )
    }
    
    @Test("Get Shares with Success")
    func testGetShares_Success() async throws {
        // Arrange
        let userId = "testUser"
        let mockShares = [SymmetricallyEncryptedShare(encryptedContent: nil, share: Share.random())]
        localDatasourceMock.stubbedGetAllSharesUserIdAsyncResult2 = mockShares
        
        // Act
        let shares = try await sut.getShares(userId: userId)
        
        // Assert
        #expect(shares == mockShares)
        #expect(localDatasourceMock.invokedGetAllSharesUserIdAsync2)
        #expect(localDatasourceMock.invokedGetAllSharesUserIdAsyncParameters2?.userId == userId)
    }
}

//var symmetricKeyProvider: SymmetricKeyProviderMock!
//var userManager: UserManagerProtocolMock!
//var localDatasource: LocalItemDatasourceProtocolMock!
//var remoteDatasource: RemoteItemDatasourceProtocol!
//var shareEventIDRepository: ShareEventIDRepositoryProtocol!
//var passKeyManager: PassKeyManagerProtocol!
//var logManager: LogManagerProtocol!
//var sut: ItemRepositoryProtocol!
//var cancellable: AnyCancellable?
//
//override func setUp() {
//    super.setUp()
//    symmetricKeyProvider = SymmetricKeyProviderMock()
//    localDatasource = LocalItemDatasourceProtocolMock()
//    userManager = UserManagerProtocolMock()
//    localDatasource.stubbedGetAllPinnedItemsResult = []
//    remoteDatasource = RemoteItemDatasourceProtocolMock()
//    shareEventIDRepository = ShareEventIDRepositoryProtocolMock()
//    passKeyManager = PassKeyManagerProtocolMock()
//    logManager = LogManagerProtocolMock()
//}

//private final class MockedRemoteDatasource: RemoteTelemetryEventDatasourceProtocol {
//    func send(userId: String, events: [Client.EventInfo]) async throws {}
//
//    func send(events: [EventInfo]) async throws {}
//}
//
//private struct MockedCurrentDateProvider: CurrentDateProviderProtocol {
//    var currentDate = Date.now
//    func getCurrentDate() -> Date { currentDate }
//}

//@Suite(.tags(.repository))
//struct TelemetryEventRepositoryTests {
//    let localDatasource: LocalTelemetryEventDatasourceProtocol
//    let localAccessDatasource: LocalAccessDatasourceProtocolMock
//    let thresholdProvider: TelemetryThresholdProviderMock
//    let userSettingsRepository: UserSettingsRepositoryProtocolMock
//    let userManager: UserManagerProtocolMock
//    let itemReadEventRepository: ItemReadEventRepositoryProtocolMock
//    var sut: TelemetryEventRepositoryProtocol!
//
//    init() {
//        localDatasource = LocalTelemetryEventDatasource(databaseService: DatabaseService(inMemory: true))
//        localAccessDatasource = .init()
//        thresholdProvider = .init()
//        userSettingsRepository = .init()
//        userManager = .init()
//        userManager.stubbedGetActiveUserDataResult = UserData.preview
//        itemReadEventRepository = .init()
//    }
//}
//
//extension TelemetryEventRepositoryTests {
//    @Test("Add new events")
//    mutating func testAddNewEvents() async throws {
//        // Given
//        let userId1 = String.random()
//        let userId2 = String.random()
//        let userId3 = String.random()
//        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
//                                                    thresholdProvider: thresholdProvider)
//        sut = TelemetryEventRepository(localDatasource: localDatasource,
//                                       remoteDatasource: MockedRemoteDatasource(),
//                                       userSettingsRepository: userSettingsRepository,
//                                       localAccessDatasource: LocalAccessDatasourceProtocolMock(),
//                                       itemReadEventRepository: itemReadEventRepository,
//                                       logManager: LogManager.dummyLogManager(),
//                                       scheduler: telemetryScheduler,
//                                       userManager: userManager)
//
//        // When
//        try await sut.addNewEvent(userId: userId1, type: .create(.login))
//        try await sut.addNewEvent(userId: userId1, type: .read(.alias))
//        try await sut.addNewEvent(userId: userId2, type: .update(.note))
//        try await sut.addNewEvent(userId: userId3, type: .delete(.login))
//        let events1 = try await localDatasource.getOldestEvents(count: 100, userId: userId1)
//        let events2 = try await localDatasource.getOldestEvents(count: 100, userId: userId2)
//        let events3 = try await localDatasource.getOldestEvents(count: 100, userId: userId3)
//
//        // Then
//        #expect(events1.count == 2)
//        #expect(events1[0].type == .create(.login))
//        #expect(events1[1].type == .read(.alias))
//
//        #expect(events2.count == 1)
//        #expect(events2[0].type == .update(.note))
//
//        #expect(events3.count == 1)
//        #expect(events3[0].type == .delete(.login))
//    }
//
//
//
//final class ShareRepositoryTests: XCTestCase {
//    private var repository: ShareRepository!
//    private var symmetricKeyProviderMock: SymmetricKeyProviderMock!
//    private var userManagerMock: UserManagerProtocolMock!
//    private var localDatasourceMock: LocalShareDatasourceProtocolMock!
//    private var remoteDatasourceMock: RemoteShareDatasourceProtocolMock!
//    private var passKeyManagerMock: PassKeyManagerProtocolMock!
//    private var logManagerMock: LogManagerProtocolMock!
//    private var logger: Logger!
//
//    override func setUp() {
//        super.setUp()
//
//        symmetricKeyProviderMock = SymmetricKeyProviderMock()
//        userManagerMock = UserManagerProtocolMock()
//        localDatasourceMock = LocalShareDatasourceProtocolMock()
//        remoteDatasourceMock = RemoteShareDatasourceProtocolMock()
//        passKeyManagerMock = PassKeyManagerProtocolMock()
//        logManagerMock = LogManagerProtocolMock()
//
//        logger = Logger(manager: logManagerMock)
//        repository = ShareRepository(
//            symmetricKeyProvider: symmetricKeyProviderMock,
//            userManager: userManagerMock,
//            localDatasource: localDatasourceMock,
//            remoteDatasource: remoteDatasourceMock,
//            passKeyManager: passKeyManagerMock,
//            logManager: logManagerMock
//        )
//    }
//
//    override func tearDown() {
//        symmetricKeyProviderMock = nil
//        userManagerMock = nil
//        localDatasourceMock = nil
//        remoteDatasourceMock = nil
//        passKeyManagerMock = nil
//        logManagerMock = nil
//        logger = nil
//        repository = nil
//
//        super.tearDown()
//    }
//
//    func testGetShares_Success() async throws {
//        // Arrange
//        let userId = "testUser"
//        let mockShares = [SymmetricallyEncryptedShare(share: Share(), encryptedContent: "encryptedContent")]
//        localDatasourceMock.getAllSharesReturnValue = mockShares
//
//        // Act
//        let shares = try await repository.getShares(userId: userId)
//
//        // Assert
//        XCTAssertEqual(shares, mockShares)
//        XCTAssertTrue(localDatasourceMock.getAllSharesCalled)
//        XCTAssertEqual(localDatasourceMock.getAllSharesReceivedArguments?.userId, userId)
//    }
//
//    func testGetShares_Failure() async throws {
//        // Arrange
//        let userId = "testUser"
//        let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
//        localDatasourceMock.getAllSharesThrowableError = expectedError
//
//        // Act & Assert
//        await XCTAssertThrowsError(try await repository.getShares(userId: userId)) { error in
//            XCTAssertEqual(error as NSError, expectedError)
//        }
//        XCTAssertTrue(localDatasourceMock.getAllSharesCalled)
//    }
//
//    func testGetShare_Success() async throws {
//        // Arrange
//        let userId = "testUser"
//        let shareId = "shareId"
//        let expectedShare = Share()
//        userManagerMock.getActiveUserIdReturnValue = userId
//        localDatasourceMock.getShareReturnValue = LocalShareDatasourceProtocolMock.GetShareResponse(
//            share: expectedShare
//        )
//
//        // Act
//        let share = try await repository.getShare(shareId: shareId)
//
//        // Assert
//        XCTAssertEqual(share, expectedShare)
//        XCTAssertTrue(userManagerMock.getActiveUserIdCalled)
//        XCTAssertTrue(localDatasourceMock.getShareCalled)
//    }
//
//    func testDeleteAllCurrentUserSharesLocally_Success() async throws {
//        // Arrange
//        let userId = "testUser"
//        userManagerMock.getActiveUserIdReturnValue = userId
//
//        // Act
//        try await repository.deleteAllCurrentUserSharesLocally()
//
//        // Assert
//        XCTAssertTrue(userManagerMock.getActiveUserIdCalled)
//        XCTAssertTrue(localDatasourceMock.removeAllSharesCalled)
//        XCTAssertEqual(localDatasourceMock.removeAllSharesReceivedArguments?.userId, userId)
//    }
//
//    func testUpsertShares_EmitsEventStream() async throws {
//        // Arrange
//        let userId = "testUser"
//        let shares = [Share()]
//        let eventStream = CurrentValueSubject<VaultSyncProgressEvent, Never>(.idle)
//        userManagerMock.getActiveUserIdReturnValue = userId
//        symmetricKeyProviderMock.getSymmetricKeyReturnValue = SymmetricKey()
//        localDatasourceMock.upsertSharesReturnValue = Void()
//
//        let expectation = XCTestExpectation(description: "Event stream should emit decryptedVault events")
//        let cancellable = eventStream.sink { event in
//            if case .decryptedVault(_) = event {
//                expectation.fulfill()
//            }
//        }
//
//        // Act
//        try await repository.upsertShares(userId: userId, shares: shares, eventStream: eventStream)
//
//        // Assert
//        wait(for: [expectation], timeout: 2.0)
//        XCTAssertTrue(localDatasourceMock.upsertSharesCalled)
//        cancellable.cancel()
//    }
//}
