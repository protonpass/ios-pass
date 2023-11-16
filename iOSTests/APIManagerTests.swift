//
// APIManagerTests.swift
// Proton Pass - Created on 23/02/2023.
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

import Combine
import Core
import Factory
@testable import Proton_Pass
import ProtonCoreKeymaker
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsCore
import XCTest


private extension SharedToolingContainer {
    func setUpAPiMocks() {
        Scope.singleton.reset()
        self.keychain.register { KeychainMock() }
        self.mainKeyProvider.register { MainKeyProviderMock() }
    }
}

final class APIManagerTests: XCTestCase {
    var keychain: KeychainMock!
    var mainKeyProvider: MainKeyProviderMock!
    let unauthSessionKey = AppDataKey.unauthSessionCredentials.rawValue
    let userDataKey = AppDataKey.userData.rawValue
    private var sessionPublisher: AnyCancellable?

    let unauthSessionCredentials = AuthCredential(sessionID: "test_session_id",
                                                  accessToken: "test_access_token",
                                                  refreshToken: "test_refresh_token",
                                                  userName: "",
                                                  userID: "",
                                                  privateKey: nil,
                                                  passwordKeySalt: nil)

    let userData = UserData(
        credential: .init(sessionID: "test_session_id",
                          accessToken: "test_access_token",
                          refreshToken: "test_refresh_token",
                          userName: "test_user_name",
                          userID: "test_user_id",
                          privateKey: nil,
                          passwordKeySalt: nil),
        user: .init(ID: "test_id",
                    name: nil,
                    usedSpace: .zero,
                    currency: .empty,
                    credit: .zero,
                    maxSpace: .zero,
                    maxUpload: .zero,
                    role: .zero,
                    private: .zero,
                    subscribed: [],
                    services: .zero,
                    delinquent: .zero,
                    orgPrivateKey: .empty,
                    email: .empty,
                    displayName: .empty,
                    keys: .empty),
        salts: .empty,
        passphrases: [:],
        addresses: .empty,
        scopes: ["test_scope"]
    )

    let mainKey: MainKey = Array(repeating: .zero, count: 32)

    override func setUp() {
        super.setUp()
        SharedToolingContainer.shared.setUpAPiMocks()
        SharedDataContainer.shared.appData.reset()
        keychain = SharedToolingContainer.shared.keychain() as? KeychainMock
        mainKeyProvider = SharedToolingContainer.shared.mainKeyProvider() as? MainKeyProviderMock
    }

    override func tearDown() {
        mainKeyProvider = nil
        keychain = nil
        sessionPublisher?.cancel()
        sessionPublisher = nil
        super.tearDown()
    }

    func givenApiManager() -> APIManager { .init() }

    func testAPIServiceIsCreatedWithoutSessionIfNoSessionIsPersisted() {
        // GIVEN
        keychain.dataStub.bodyIs { _, _ in nil } // no session in keychain
        mainKeyProvider.mainKeyStub.fixture = mainKey

        // WHEN
        let apiManager = givenApiManager()

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, .empty)
        XCTAssertNil(apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID))
    }

    func testAPIServiceIsCreatedWithSessionIfUnauthSessionIsPersisted() throws {
        // GIVEN
        let unauthSessionCredentialsData = try JSONEncoder().encode(unauthSessionCredentials)
        let lockedSession = try Locked<Data>(clearValue: unauthSessionCredentialsData, with: mainKey)
        keychain.dataStub.bodyIs { _, key in
            guard key == self.unauthSessionKey else { return nil }
            return lockedSession.encryptedValue // unauth session in keychain
        }
        mainKeyProvider.mainKeyStub.fixture = mainKey

        // WHEN
        let apiManager = givenApiManager()

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "test_session_id")
        XCTAssertEqual(apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID),
                       Credential(unauthSessionCredentials))
    }

    func testAPIServiceIsCreatedWithSessionIfAuthSessionIsPersisted() throws {
        // GIVEN
        let userDataData = try JSONEncoder().encode(userData)
        let lockedSession = try Locked<Data>(clearValue: userDataData, with: mainKey)
        keychain.dataStub.bodyIs { _, key in
            guard key == self.userDataKey else { return nil }
            return lockedSession.encryptedValue // UserData in keychain
        }
        mainKeyProvider.mainKeyStub.fixture = mainKey

        // WHEN
        let apiManager = givenApiManager()

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "test_session_id")
        XCTAssertEqual(apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID),
                       Credential(userData.credential))
    }

    func testAPIServiceUpdateCredentialsUpdatesBothAPIServiceAndStorageForUnauthSession() throws {
        // GIVEN
        mainKeyProvider.mainKeyStub.fixture = mainKey
        let apiManager = givenApiManager()

        // WHEN
        apiManager.sessionIsAvailable(authCredential: unauthSessionCredentials, scopes: .empty)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "test_session_id")
        XCTAssertEqual(apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID),
                       Credential(unauthSessionCredentials))
        XCTAssertTrue(keychain.setDataStub.wasCalledExactlyOnce)
        XCTAssertEqual(keychain.setDataStub.lastArguments?.second,
                       AppDataKey.unauthSessionCredentials.rawValue)
    }

    func testAPIServiceUpdateCredentialsUpdatesBothAPIServiceAndStorageForAuthSession() throws {
        // GIVEN
        let userDataData = try JSONEncoder().encode(userData)
        let lockedSession = try Locked<Data>(clearValue: userDataData, with: mainKey)
        keychain.dataStub.bodyIs { _, key in
            guard key == self.userDataKey else { return nil }
            return lockedSession.encryptedValue // auth session in keychain
        }
        mainKeyProvider.mainKeyStub.fixture = mainKey
        let apiManager = givenApiManager()

        // WHEN
        apiManager.sessionIsAvailable(authCredential: userData.credential,
                                      scopes: userData.scopes)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "test_session_id")
        XCTAssertEqual(apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID),
                       Credential(userData.credential, scopes: userData.scopes))
        XCTAssertTrue(keychain.setDataStub.wasCalledExactlyOnce) // setting auth session
        XCTAssertEqual(keychain.setDataStub.lastArguments?.second,
                       AppDataKey.userData.rawValue)
        XCTAssertTrue(keychain.removeStub.wasCalledExactlyOnce) // removing unauth session
        XCTAssertEqual(keychain.removeStub.lastArguments?.value,
                       AppDataKey.unauthSessionCredentials.rawValue)
    }

    func testAPIServiceClearCredentialsClearsAPIServiceAndUnauthSessionStorage() throws {
        // GIVEN
        let unauthSessionData = try JSONEncoder().encode(unauthSessionCredentials)
        let lockedSession = try Locked<Data>(clearValue: unauthSessionData, with: mainKey)
        keychain.dataStub.bodyIs { _, key in
            guard key == self.unauthSessionKey else { return nil }
            return lockedSession.encryptedValue // auth session in keychain
        }
        mainKeyProvider.mainKeyStub.fixture = mainKey
        let apiManager = givenApiManager()

        // WHEN
        apiManager.clearCredentials()

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "")
        XCTAssertNil(apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID))
        XCTAssertTrue(keychain.removeStub.wasCalledExactlyOnce) // removing unauth session
        XCTAssertEqual(keychain.removeStub.lastArguments?.value,
                       AppDataKey.unauthSessionCredentials.rawValue)
    }

    func testAPIServiceUnauthSessionInvalidationClearsCredentials() throws {
        // GIVEN
        let unauthSessionData = try JSONEncoder().encode(unauthSessionCredentials)
        let lockedSession = try Locked<Data>(clearValue: unauthSessionData, with: mainKey)
        keychain.dataStub.bodyIs { _, key in
            guard key == self.unauthSessionKey else { return nil }
            return lockedSession.encryptedValue // auth session in keychain
        }
        mainKeyProvider.mainKeyStub.fixture = mainKey
        let apiManager = givenApiManager()

        apiManager.sessionWasInvalidated(for: "test_session_id", isAuthenticatedSession: false)
        
        XCTAssertEqual(apiManager.apiService.sessionUID, "")
        XCTAssertNil(apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID))
    }

    func testAPIServiceAuthSessionInvalidationClearsCredentialsAndLogsOut() throws {
        // GIVEN
        let userDataData = try JSONEncoder().encode(userData)
        let lockedSession = try Locked<Data>(clearValue: userDataData, with: mainKey)
        keychain.dataStub.bodyIs { _, key in
            guard key == self.userDataKey else { return nil }
            return lockedSession.encryptedValue // auth session in keychain
        }
        mainKeyProvider.mainKeyStub.fixture = mainKey
        let apiManager = givenApiManager()

        let sessionWasInvalidatedExpectation = expectation(description: "Session should be invalidated")
        sessionPublisher = apiManager.sessionWasInvalidated
            .sink { [weak self] _ in
                sessionWasInvalidatedExpectation.fulfill()
            }
        
        apiManager.sessionWasInvalidated(for: "test_session_id", isAuthenticatedSession: true)

        wait(for: [sessionWasInvalidatedExpectation], timeout: 3)

        XCTAssertEqual(apiManager.apiService.sessionUID, "")
        XCTAssertNil(apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID))
    }

    func testAPIServiceAuthCredentialsUpdateSetsNewUnauthCredentials() throws {
        // GIVEN
        let unauthSessionData = try JSONEncoder().encode(unauthSessionCredentials)
        let lockedSession = try Locked<Data>(clearValue: unauthSessionData, with: mainKey)
        keychain.dataStub.bodyIs { _, key in
            guard key == self.unauthSessionKey else { return nil }
            return lockedSession.encryptedValue // auth session in keychain
        }
        mainKeyProvider.mainKeyStub.fixture = mainKey
        let apiManager = givenApiManager()

        let newUnauthCredentials = AuthCredential(sessionID: "new_test_session_id",
                                                  accessToken: "new_test_access_token",
                                                  refreshToken: "new_test_refresh_token",
                                                  userName: "",
                                                  userID: "",
                                                  privateKey: nil,
                                                  passwordKeySalt: nil)

        // WHEN
        apiManager.credentialsWereUpdated(authCredential: newUnauthCredentials,
                                          credential: Credential(newUnauthCredentials),
                                          for: unauthSessionCredentials.sessionID
        )

        // THEN
        XCTAssertTrue(keychain.setDataStub.wasCalledExactlyOnce)
        XCTAssertEqual(keychain.setDataStub.lastArguments?.second, unauthSessionKey)
        let encryptedValue = try XCTUnwrap(keychain.setDataStub.lastArguments?.first)
        let unlockedSessionData = try Locked<Data>(encryptedValue: encryptedValue)
            .unlock(with: mainKey)
        let unlockedSession = try JSONDecoder().decode(AuthCredential.self, from: unlockedSessionData)

        /*
         let newUnauthSessionData = try JSONEncoder().encode(newUnauthCredentials)
         XCTAssertEqual(unlockedSessionData, newUnauthSessionData)

         This no more works after upgrading to Xcode 15 and iOS 17
         Work around by asserting field by field
         */
        XCTAssertEqual(unlockedSession.accessToken, newUnauthCredentials.accessToken)
        XCTAssertEqual(unlockedSession.refreshToken, newUnauthCredentials.refreshToken)
        XCTAssertEqual(unlockedSession.sessionID, newUnauthCredentials.sessionID)
        XCTAssertEqual(unlockedSession.userName, newUnauthCredentials.userName)
        XCTAssertEqual(unlockedSession.userID, newUnauthCredentials.userID)
    }

    func testAPIServiceAuthCredentialsUpdateUpdatesAuthSesson() throws {
        // GIVEN
        let userDataData = try JSONEncoder().encode(userData)
        let lockedSession = try Locked<Data>(clearValue: userDataData, with: mainKey)
        keychain.dataStub.bodyIs { _, key in
            guard key == self.userDataKey else { return nil }
            return lockedSession.encryptedValue // auth session in keychain
        }
        mainKeyProvider.mainKeyStub.fixture = mainKey
        let apiManager = givenApiManager()

        let newUnauthCredentials = AuthCredential(sessionID: "new_test_session_id",
                                                  accessToken: "new_test_access_token",
                                                  refreshToken: "new_test_refresh_token",
                                                  userName: "",
                                                  userID: "",
                                                  privateKey: nil,
                                                  passwordKeySalt: nil)

        // WHEN
        apiManager.credentialsWereUpdated(authCredential: newUnauthCredentials,
                                          credential: Credential(newUnauthCredentials),
                                          for: unauthSessionCredentials.sessionID
        )

        // THEN
        XCTAssertTrue(keychain.setDataStub.wasCalledExactlyOnce)
        XCTAssertEqual(keychain.setDataStub.lastArguments?.second, userDataKey)
        let encryptedValue = try XCTUnwrap(keychain.setDataStub.lastArguments?.first)
        let unlockedUserData = try Locked<Data>(encryptedValue: encryptedValue)
            .unlock(with: mainKey)
        let newUserData = try JSONDecoder().decode(UserData.self, from: unlockedUserData)
        XCTAssertEqual(Credential(newUserData.credential), Credential(newUnauthCredentials))
        XCTAssertEqual(newUserData.user, userData.user)
    }
}
