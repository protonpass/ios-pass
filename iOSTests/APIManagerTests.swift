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
import Client
import Factory
@testable import Proton_Pass
import ProtonCoreKeymaker
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreAuthentication
import ProtonCoreTestingToolkitUnitTestsCore
import CryptoKit
import XCTest

@MainActor
final class APIManagerTests: XCTestCase {
    var credentialProvider: CredentialProvider!
    var mainKeyProvider: MainKeyProviderMock!
    private var sessionPublisher: AnyCancellable?

    let unauthSessionCredentials = AuthCredential(sessionID: "test_session_id",
                                                  accessToken: "test_access_token_unauth",
                                                  refreshToken: "test_refresh_token_unauth",
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

    func givenApiManager() -> APIManager { .init() }

    func testAPIServiceIsCreatedWithoutSessionIfNoSessionIsPersisted() {
        // GIVEN
        SharedDataContainer.shared.appData().resetData()

        // WHEN
        let apiManager = givenApiManager()

        var credential: Credential?
        let expectation = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, .empty)
        XCTAssertNil(credential)
    }

    func testAPIServiceIsCreatedWithSessionIfUnauthSessionIsPersisted() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(unauthSessionCredentials)
        
        // WHEN
        let apiManager = givenApiManager()

        var credential: Credential?
        let expectation = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "test_session_id")
        XCTAssertEqual(credential, Credential(unauthSessionCredentials))
    }

    func testAPIServiceIsCreatedWithSessionIfAuthSessionIsPersisted() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(userData.credential)

        // WHEN
        let apiManager = givenApiManager()

        var credential: Credential?
        let expectation = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "test_session_id")
        XCTAssertEqual(credential, Credential(userData.credential))
    }

    func testAPIServiceUpdateCredentialsUpdatesBothAPIServiceAndStorageForUnauthSession() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(userData.credential)

        // WHEN
        let apiManager = givenApiManager()
        apiManager.authHelper.onUpdate(credential: Credential(unauthSessionCredentials),
                                       sessionUID: unauthSessionCredentials.sessionID)

        var credential: Credential?
        let expectation = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "test_session_id")
        XCTAssertEqual(credential, Credential(unauthSessionCredentials))
    }


    func testAPIServiceUpdateCredentialsUpdatesBothAPIServiceAndStorageForAuthSession() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(unauthSessionCredentials)

        // WHEN
        let apiManager = givenApiManager()
        apiManager.authHelper.onUpdate(credential: Credential(userData.credential), sessionUID: userData.credential.sessionID)

        var credential: Credential?
        let expectation = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "test_session_id")
        XCTAssertEqual(credential, Credential(userData.credential))
    }

    func testAPIServiceClearCredentialsClearsAPIServiceAndUnauthSessionStorage() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(userData.credential)

        // WHEN
        let apiManager = givenApiManager()
        apiManager.clearCredentials()

        var credential: Credential?
        let expectation = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "")
        XCTAssertNil(credential)
    }

    func testAPIServiceUnauthSessionInvalidationClearsCredentials() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(unauthSessionCredentials)

        // WHEN
        let apiManager = givenApiManager()
        apiManager.sessionWasInvalidated(for: "test_session_id", isAuthenticatedSession: false)

        var credential: Credential?
        let expectation = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "")
        XCTAssertNil(credential)
    }
    
    
    func testAPIServiceShouldAlwayGetTheLastAuthCredentialsFromKeychain() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(unauthSessionCredentials)

        // WHEN
        let apiManager = givenApiManager()

        var credential: Credential?
        let expectation1 = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 0.1)

        XCTAssertEqual(credential, Credential(unauthSessionCredentials))

        SharedDataContainer.shared.credentialProvider().setCredential(userData.credential)

        let expectation2 = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.1)

        // THEN
        XCTAssertEqual(credential, Credential(userData.credential))
    }

    func testAPIServiceAuthSessionInvalidationClearsCredentialsAndLogsOut() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(userData.credential)

        // WHEN
        let apiManager = givenApiManager()

        let sessionWasInvalidatedExpectation = expectation(description: "Session should be invalidated")
        sessionPublisher = apiManager.sessionWasInvalidated
            .sink { [weak self] _ in
                sessionWasInvalidatedExpectation.fulfill()
            }
        
        apiManager.sessionWasInvalidated(for: "test_session_id", isAuthenticatedSession: true)

        var credential: Credential?
        let credentialExpectation = XCTestExpectation()
        Task {
            credential = await apiManager.authHelper.credential(sessionUID: apiManager.apiService.sessionUID)
            credentialExpectation.fulfill()
        }
        wait(for: [credentialExpectation], timeout: 0.1)

        wait(for: [sessionWasInvalidatedExpectation], timeout: 3)

        // THEN
        XCTAssertEqual(apiManager.apiService.sessionUID, "")
        XCTAssertNil(credential)
    }

    func testAPIServiceAuthCredentialsUpdateSetsNewUnauthCredentials() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(unauthSessionCredentials)

        let apiManager = givenApiManager()

        let newUnauthCredentials = AuthCredential(sessionID: "test_session_id",
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
        var unlockedSession: AuthCredential!
        let expectation = XCTestExpectation()
        Task {
            guard let authCredential = await apiManager.authHelper.authCredential(sessionUID: unauthSessionCredentials.sessionID) else {
                XCTFail("Should contain authCredential")
                return
            }
            unlockedSession = authCredential
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        XCTAssertEqual(unlockedSession.accessToken, newUnauthCredentials.accessToken)
        XCTAssertEqual(unlockedSession.refreshToken, newUnauthCredentials.refreshToken)
        XCTAssertEqual(unlockedSession.sessionID, newUnauthCredentials.sessionID)
        XCTAssertEqual(unlockedSession.userName, newUnauthCredentials.userName)
        XCTAssertEqual(unlockedSession.userID, newUnauthCredentials.userID)
    }

    func testAPIServiceAuthCredentialsUpdateUpdatesAuthSession() throws {
        // GIVEN
        SharedDataContainer.shared.credentialProvider().setCredential(userData.credential)

        let apiManager = givenApiManager()

        let newUnauthCredentials = AuthCredential(sessionID: "test_session_id",
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

        var newAuthCredential: AuthCredential!
        let expectation = XCTestExpectation()
        Task {
            guard let authCredential = await apiManager.authHelper.authCredential(sessionUID: userData.credential.sessionID) else {
                XCTFail("Should contain AuthCredential")
                return
            }
            newAuthCredential = authCredential
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(Credential(newAuthCredential), Credential(newUnauthCredentials))
    }
}
