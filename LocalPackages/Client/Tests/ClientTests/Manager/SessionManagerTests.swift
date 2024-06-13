//
// SessionManagerTests.swift
// Proton Pass - Created on 13/06/2024.
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
//

@testable import Client
import ClientMocks
import CoreMocks
import Entities
import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking
import XCTest

private struct PreferencesMigratorMock: PreferencesMigrator {
    func migratePreferences() -> (AppPreferences, SharedPreferences, UserPreferences) {
        (.random(), .random(), .random())
    }
}

final class SessionManagerTests: XCTestCase {
    var symmetricKeyProviderMockFactory: SymmetricKeyProviderMockFactory!
    var userDataDatasource: LocalUserDataDatasourceProtocolMock!
    var authDatasource: LocalAuthCredentialDatasource!
    var unauthDatasource: LocalUnauthCredentialDatasourceProtocolMock!
    var appPreferencesDatasource: LocalAppPreferencesDatasourceProtocolMock!
    var preferencesManager: PreferencesManagerProtocol!
    var module: PassModule!
    var sut: SessionManagerProtocol!

    override func setUp() {
        super.setUp()
        userDataDatasource = .init()
        userDataDatasource.closureRemove = { [weak self] in
            guard let self else { return }
            let userId = userDataDatasource.invokedRemoveParameters?.userId
            userDataDatasource.stubbedGetAllResult.removeAll(where: { $0.userId == userId })
        }
        symmetricKeyProviderMockFactory = .init()
        symmetricKeyProviderMockFactory.setUp()
        authDatasource = .init(symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                               databaseService: DatabaseService(inMemory: true))
        unauthDatasource = .init()
        appPreferencesDatasource = .init()
        module = .random()!
        let logManager = LogManagerProtocolMock()
        preferencesManager = PreferencesManager(
            currentUserIdProvider: CurrentUserIdProviderMock(),
            appPreferencesDatasource: appPreferencesDatasource,
            sharedPreferencesDatasource: LocalSharedPreferencesDatasourceProtocolMock(),
            userPreferencesDatasource: LocalUserPreferencesDatasourceProtocolMock(),
            logManager: logManager,
            preferencesMigrator: PreferencesMigratorMock())
        sut = SessionManager(userDataDatasource: userDataDatasource,
                             authDatasource: authDatasource,
                             unauthDatasource: unauthDatasource,
                             preferencesManager: preferencesManager,
                             module: module,
                             logManager: logManager)
    }

    override func tearDown() {
        symmetricKeyProviderMockFactory = nil
        userDataDatasource = nil
        authDatasource = nil
        unauthDatasource = nil
        appPreferencesDatasource = nil
        preferencesManager = nil
        module = nil
        sut = nil
        super.tearDown()
    }
}

extension SessionManagerTests {
    func testSetUp() async throws {
        // Given
        let userCount = Int.random(in: 5...10)
        let givenUserDatas = givenUserDatas(userCount)

        // When
        try await sut.setUp()

        // Then
        let userDatas = sut.userDatas.value
        XCTAssertEqual(userDatas.count, userCount)
        for givenUserData in givenUserDatas {
            XCTAssertTrue(userDatas.contains { $0.userId == givenUserData.userId })
        }
    }

    func testGetActiveUserData() async throws {
        // Given
        let givenUserDatas = givenUserDatas()
        let activeUser = try XCTUnwrap(givenUserDatas.randomElement())

        try await preferencesManager.setUp()
        try await sut.setUp()
        try await makeActiveUser(activeUser)

        // When
        let activeUserData = try sut.getActiveUserData()

        // Then
        XCTAssertEqual(activeUserData?.userId, activeUser.userId)
    }

    func testGetCredentialReturnNilWhenNoAuthAndUnauthCredentialsFound() async throws {
        // Given
        userDataDatasource.stubbedGetAllResult = []
        try await preferencesManager.setUp()
        try await sut.setUp()

        // When
        let credential = try await sut.getCredential()

        // Then
        XCTAssertNil(credential)
    }

    func testGetCredentialReturnAuthCredentialOfActiveUser() async throws {
        // Given
        let givenUserDatas = givenUserDatas()
        let activeUser = try XCTUnwrap(givenUserDatas.randomElement())
        let activeUserId = activeUser.userId
        try await preferencesManager.setUp()
        try await sut.setUp()
        try await makeActiveUser(activeUser)

        let hostAppCredential = try await givenAuthCredential(userId: activeUserId,
                                                              module: .hostApp)
        let autofillCredential = try await givenAuthCredential(userId: activeUserId,
                                                               module: .autoFillExtension)
        let shareCredential = try await givenAuthCredential(userId: activeUserId,
                                                                      module: .shareExtension)

        // When
        let credential = try await XCTUnwrapAsync(await sut.getCredential())

        // Then
        switch module {
        case .hostApp:
            XCTAssertEqual(hostAppCredential.sessionID, credential.sessionID)
        case .autoFillExtension:
            XCTAssertEqual(autofillCredential.sessionID, credential.sessionID)
        case .shareExtension:
            XCTAssertEqual(shareCredential.sessionID, credential.sessionID)
        case .none:
            XCTFail("Unknown module")
        }
    }

    func testGetCredentialReturnUnauthCredentialWhenNoActiveUser() async throws {
        // Given
        userDataDatasource.stubbedGetAllResult = []
        let unauthCredential = AuthCredential.random()
        unauthDatasource.stubbedGetUnauthCredentialResult = unauthCredential

        try await preferencesManager.setUp()
        try await preferencesManager.updateAppPreferences(\.activeUserId, value: nil)
        try await sut.setUp()

        // When
        let credential = try await XCTUnwrapAsync(await sut.getCredential())

        // Then
        XCTAssertEqual(unauthCredential.sessionID, credential.sessionID)
    }

    func testUpsertAuthCredential() async throws {
        // Given
        let givenUserDatas = givenUserDatas()
        let activeUser = try XCTUnwrap(givenUserDatas.randomElement())

        let authCredential = AuthCredential.random()

        try await preferencesManager.setUp()
        try await sut.setUp()
        try await makeActiveUser(activeUser)

        // When
        try await sut.upsert(credential: authCredential)
        let retrievedCredential = try await authDatasource.getCredential(userId: activeUser.userId,
                                                                         module: module)

        // Then
        XCTAssertEqual(retrievedCredential?.sessionID, authCredential.sessionID)
    }

    func testUpsertUnauthCredential() async throws {
        // Given
        userDataDatasource.stubbedGetAllResult = []
        let unauthCredential = AuthCredential.random(userId: "")

        try await preferencesManager.setUp()
        try await sut.setUp()

        // When
        try await sut.upsert(credential: unauthCredential)

        // Then
        XCTAssertTrue(unauthDatasource.invokedUpsertUnauthCredentialfunction)

        let setUnauthCredential = try XCTUnwrap(unauthDatasource.invokedUpsertUnauthCredentialParameters?.credential)
        XCTAssertTrue(setUnauthCredential.isEqual(to: unauthCredential))
    }

    func testRemoveAllCredentials() async throws {
        // Given
        let userDatas = givenUserDatas()
        let activeUser = try XCTUnwrap(userDatas.randomElement())
        let activeUserId = activeUser.userId

        // Create credentials for all users
        for userData in userDatas {
            try await authDatasource.upsertCredential(userId: userData.userId, credential: .random(),
                                                      module: .hostApp)
            try await authDatasource.upsertCredential(userId: userData.userId, credential: .random(),
                                                      module: .autoFillExtension)
            try await authDatasource.upsertCredential(userId: userData.userId, credential: .random(),
                                                      module: .shareExtension)
        }

        try await preferencesManager.setUp()
        try await sut.setUp()
        try await makeActiveUser(activeUser)

        // Then
        // Credentials of active users are available
        XCTAssertEqual((try sut.getActiveUserData())?.userId, activeUser.userId)
        try await XCTAssertNotNilAsync(
            await authDatasource.getCredential(userId: activeUserId,
                                               module: .hostApp))
        try await XCTAssertNotNilAsync(
            await authDatasource.getCredential(userId: activeUserId,
                                               module: .autoFillExtension))
        try await XCTAssertNotNilAsync(
            await authDatasource.getCredential(userId: activeUserId,
                                               module: .shareExtension))

        // When
        try await sut.removeAllCredentials(userId: activeUserId)

        // Then
        // Credentials of active user are deleted and there's no more active user
        try await XCTAssertNilAsync(
            await authDatasource.getCredential(userId: activeUserId,
                                               module: .hostApp))
        try await XCTAssertNilAsync(
            await authDatasource.getCredential(userId: activeUserId,
                                               module: .autoFillExtension))
        try await XCTAssertNilAsync(
            await authDatasource.getCredential(userId: activeUserId,
                                               module: .shareExtension))

        XCTAssertEqual(sut.userDatas.value.count, userDatas.count - 1)
        XCTAssertNil(try sut.getActiveUserData())

        // When
        let inactiveUser = try XCTUnwrap(sut.userDatas.value.randomElement())
        let inactiveUserId = inactiveUser.userId

        // Then
        // Credentials of other inactive user are available
        try await XCTAssertNotNilAsync(
            await authDatasource.getCredential(userId: inactiveUserId,
                                               module: .hostApp))
        try await XCTAssertNotNilAsync(
            await authDatasource.getCredential(userId: inactiveUserId,
                                               module: .autoFillExtension))
        try await XCTAssertNotNilAsync(
            await authDatasource.getCredential(userId: inactiveUserId,
                                               module: .shareExtension))

        // When
        try await sut.removeAllCredentials(userId: inactiveUserId)

        // Then
        try await XCTAssertNilAsync(
            await authDatasource.getCredential(userId: inactiveUserId,
                                               module: .hostApp))
        try await XCTAssertNilAsync(
            await authDatasource.getCredential(userId: inactiveUserId,
                                               module: .autoFillExtension))
        try await XCTAssertNilAsync(
            await authDatasource.getCredential(userId: inactiveUserId,
                                               module: .shareExtension))

        XCTAssertEqual(sut.userDatas.value.count, userDatas.count - 2)
    }
}

private extension SessionManagerTests {
    func givenUserDatas(_ count: Int = .random(in: 5...10)) -> [UserData] {
        let userDatas = [UserData].random(count: count, randomElement: .random())
        userDataDatasource.stubbedGetAllResult = userDatas
        return userDatas
    }

    func makeActiveUser(_ userData: UserData) async throws {
        try await preferencesManager.updateAppPreferences(\.activeUserId,
                                                           value: userData.userId)
    }

    func givenAuthCredential(userId: String,
                             module: PassModule) async throws -> AuthCredential {
        let credential = AuthCredential.random()
        try await authDatasource.upsertCredential(userId: userId,
                                                  credential: credential,
                                                  module: module)
        return credential
    }
}

private extension UserData {
    var userId: String {
        user.ID
    }
}
