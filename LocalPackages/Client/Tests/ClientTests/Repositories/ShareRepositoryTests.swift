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
import ProtonCoreLogin

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
    func getSharesWithSuccess() async throws {
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
    
    @Test("Get Shares with Failure")
    func getSharesFailure() async throws {
        // Arrange
        let userId = "testUser"
        let expectedError = PassError.unexpectedError
        localDatasourceMock.getAllSharesUserIdThrowableError2 = expectedError
        
        await #expect(throws: (any Error).self) { try await sut.getShares(userId: userId) }
        #expect(localDatasourceMock.invokedGetAllSharesUserIdAsync2)
    }
    
    @Test("Get Share with Success")
    func getShareWithSuccess() async throws {
        // Arrange
        let user = UserData.random()
        let shareId = "shareId"
        let expectedShare = Share.random()
        userManager.stubbedGetActiveUserDataResult = user
        localDatasourceMock.stubbedGetShareResult = SymmetricallyEncryptedShare(encryptedContent: nil, share: expectedShare)
        
        // Act
        let share = try await sut.getShare(shareId: shareId)
        
        // Assert
        #expect(share == expectedShare)
        #expect(userManager.invokedGetActiveUserDatafunction)
        #expect(localDatasourceMock.invokedGetSharefunction)
    }
    
    @Test("Delete all local shares for current user")
    func deleteAllCurrentUserSharesLocallySuccess() async throws {
        // Arrange
        let user = UserData.random()
        userManager.stubbedGetActiveUserDataResult = user
        
        // Act
        try await sut.deleteAllCurrentUserSharesLocally()
        
        // Assert
        #expect(userManager.invokedGetActiveUserDatafunction)
        #expect(localDatasourceMock.invokedRemoveAllSharesfunction)
        #expect(localDatasourceMock.invokedRemoveAllSharesParameters?.userId == user.user.ID)
    }
}
