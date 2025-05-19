//
// AuthManagerTests.swift
// Proton Pass - Created on 10/07/2024.
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

import Combine
import Core
import CoreMocks
import ClientMocks
import FactoryKit
@testable import Client
import ProtonCoreKeymaker
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreAuthentication
import ProtonCoreTestingToolkitUnitTestsCore
import CryptoKit
import XCTest
import ProtonCoreDoh
import ProtonCoreCryptoGoImplementation

final class AuthHelperDelegateMock: AuthHelperDelegate {

    let credentialsWereUpdatedSubject: PassthroughSubject<(authCredential: ProtonCoreNetworking.AuthCredential,
                                                           credential: ProtonCoreNetworking.Credential,
                                                           sessionUID: String),Never> = .init()
    let  sessionWasInvalidatedSubject: PassthroughSubject<(sessionUID: String, isAuthenticatedSession: Bool),Never> = .init()

    func credentialsWereUpdated(authCredential: ProtonCoreNetworking.AuthCredential, credential: ProtonCoreNetworking.Credential, for sessionUID: String) {
        credentialsWereUpdatedSubject.send((authCredential, credential, sessionUID))
    }

    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        sessionWasInvalidatedSubject.send((sessionUID, isAuthenticatedSession))
    }
}

final class AuthManagerTests: XCTestCase {
    let key = SymmetricKey.random()
    let symmetricKeyProvider = NonSendableSymmetricKeyProviderMock()
    var sut: AuthManager!
    let userDefaultsKeychainMock =  UserDefaultsKeychainMock()

    var authHelperDelegateMock: AuthHelperDelegateMock!
    private var cancellables: Set<AnyCancellable>!


    override func setUp() {
        super.setUp()
        injectDefaultCryptoImplementation()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = key
        cancellables = .init()

        authHelperDelegateMock = AuthHelperDelegateMock()
        sut = AuthManager(keychain: userDefaultsKeychainMock,
                          symmetricKeyProvider: symmetricKeyProvider,
                          module: .hostApp,
                          logManager: LogManagerProtocolMock())
        sut.setUp()
    }

    override func tearDown() {
        sut = nil
        authHelperDelegateMock = nil
        try? userDefaultsKeychainMock.removeOrError(forKey: AuthManager.storageKey)
        cancellables = nil
        super.tearDown()
    }

    let baseCredentials =  Credential(UID: "test_session_id",
                                      accessToken: "test_access_token_unauth",
                                      refreshToken: "test_refresh_token_unauth",
                                      userName: "test_user_name",
                                      userID: "test_user_id",
                                      scopes: [],
                                      mailboxPassword: "")

    func testAuthManagerNoSessionIsPersisted() {
        XCTAssertNil(sut.getCredential(userId: baseCredentials.userID))
    }

    func testAuthManagerWithPersistedSession() {
        sut.onSessionObtaining(credential: baseCredentials)

        XCTAssertEqual(sut.credential(sessionUID: baseCredentials.UID)?.UID, baseCredentials.UID)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.sessionID, baseCredentials.UID)
        XCTAssertEqual(sut.getCredential(userId: baseCredentials.userID)?.sessionID, baseCredentials.UID)
    }

    func testAuthManagerWithUpdateOfPersistedSession() {
        sut.onSessionObtaining(credential: baseCredentials)

        let newCredentials =  Credential(UID: "test_session_id",
                                         accessToken: "test_access_token_unauth",
                                         refreshToken: "test_refresh_token_unauth",
                                         userName: "new_test_user_name",
                                         userID: baseCredentials.userID,
                                         scopes: [],
                                         mailboxPassword: "")

        sut.onUpdate(credential: newCredentials, sessionUID: baseCredentials.UID)

        XCTAssertEqual(sut.credential(sessionUID: baseCredentials.UID)?.userName, newCredentials.userName)
        XCTAssertEqual(sut.getCredential(userId: baseCredentials.userID)?.userName, newCredentials.userName)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.userName, newCredentials.userName)
    }

    func testAuthManagerOnAdditionalCredentialsInfoObtained() async throws {
        sut.onSessionObtaining(credential: baseCredentials)

        XCTAssertNil(sut.authCredential(sessionUID: baseCredentials.UID)?.passwordKeySalt)
        XCTAssertNil(sut.authCredential(sessionUID: baseCredentials.UID)?.privateKey)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.mailboxpassword, "")

        sut.setUpDelegate(authHelperDelegateMock)
        let expectation = expectation(description: "Should receive update event")
        let newSalt = "salttest"
        let newPrivateKey = "privatekeytest"
        let newPassword =  "test"
        authHelperDelegateMock.credentialsWereUpdatedSubject
            .sink { value in
                XCTAssertEqual(value.authCredential.passwordKeySalt, newSalt)
                XCTAssertEqual(value.authCredential.privateKey, newPrivateKey)
                XCTAssertEqual(value.authCredential.mailboxpassword, newPassword)

                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.onAdditionalCredentialsInfoObtained(sessionUID: baseCredentials.UID, password: newPassword, salt: newSalt, privateKey: newPrivateKey)

        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.passwordKeySalt, newSalt)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.privateKey, newPrivateKey)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.mailboxpassword, newPassword)
    }

    func testAuthManagerOnAuthenticatedSessionInvalidated() async throws {
        sut.onSessionObtaining(credential: baseCredentials)

        XCTAssertEqual(sut.credential(sessionUID: baseCredentials.UID)?.UID, baseCredentials.UID)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.sessionID, baseCredentials.UID)
        XCTAssertEqual(sut.getCredential(userId: baseCredentials.userID)?.sessionID, baseCredentials.UID)

        sut.setUpDelegate(authHelperDelegateMock)
        let expectation = expectation(description: "Should receive invalite session event")
        authHelperDelegateMock.sessionWasInvalidatedSubject
            .sink { [weak self] value in
                XCTAssertEqual(value.sessionUID, self?.baseCredentials.UID)
                XCTAssertEqual(value.isAuthenticatedSession, true)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.onAuthenticatedSessionInvalidated(sessionUID: baseCredentials.UID)

        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertNil(sut.credential(sessionUID: baseCredentials.UID))
        XCTAssertNil(sut.authCredential(sessionUID: baseCredentials.UID))
        XCTAssertNil(sut.getCredential(userId: baseCredentials.userID))

    }

    func testAuthManagerOnUnauthenticatedSessionInvalidated() async throws {
        sut.onSessionObtaining(credential: baseCredentials)

        XCTAssertEqual(sut.credential(sessionUID: baseCredentials.UID)?.UID, baseCredentials.UID)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.sessionID, baseCredentials.UID)
        XCTAssertEqual(sut.getCredential(userId: baseCredentials.userID)?.sessionID, baseCredentials.UID)

        sut.setUpDelegate(authHelperDelegateMock)
        let expectation = XCTestExpectation(description: "Should receive invalidated session event")
        let sessionWasInvalidatedExpectation = XCTestExpectation(description: "Session should be invalidated")

        authHelperDelegateMock.sessionWasInvalidatedSubject
            .sink { [weak self] value in
                XCTAssertEqual(value.sessionUID, self?.baseCredentials.UID)
                XCTAssertEqual(value.isAuthenticatedSession, false)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.sessionWasInvalidated
            .sink { [weak self] value in
                XCTAssertEqual(value.sessionId, self?.baseCredentials.UID)
                XCTAssertEqual(value.userId, self?.baseCredentials.userID)
                sessionWasInvalidatedExpectation.fulfill()
            }
            .store(in: &cancellables)

        sut.onUnauthenticatedSessionInvalidated(sessionUID: baseCredentials.UID)

        await fulfillment(of: [expectation, sessionWasInvalidatedExpectation], timeout: 1)
        XCTAssertNil(sut.credential(sessionUID: baseCredentials.UID))
        XCTAssertNil(sut.authCredential(sessionUID: baseCredentials.UID))
        XCTAssertNil(sut.getCredential(userId: baseCredentials.userID))
    }

    func testAuthManagerClearSessionsForSessionID() async throws {
        sut.onSessionObtaining(credential: baseCredentials)

        XCTAssertEqual(sut.credential(sessionUID: baseCredentials.UID)?.UID, baseCredentials.UID)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.sessionID, baseCredentials.UID)
        XCTAssertEqual(sut.getCredential(userId: baseCredentials.userID)?.sessionID, baseCredentials.UID)

        sut.clearSessions(sessionId:  baseCredentials.UID)
        XCTAssertNil(sut.credential(sessionUID: baseCredentials.UID))
        XCTAssertNil(sut.authCredential(sessionUID: baseCredentials.UID))
        XCTAssertNil(sut.getCredential(userId: baseCredentials.userID))
    }

    func testAuthManagerClearSessionsForUserID() async throws {
        sut.onSessionObtaining(credential: baseCredentials)

        XCTAssertEqual(sut.credential(sessionUID: baseCredentials.UID)?.UID, baseCredentials.UID)
        XCTAssertEqual(sut.authCredential(sessionUID: baseCredentials.UID)?.sessionID, baseCredentials.UID)
        XCTAssertEqual(sut.getCredential(userId: baseCredentials.userID)?.sessionID, baseCredentials.UID)

        sut.clearSessions(userId:  baseCredentials.userID)
        XCTAssertNil(sut.credential(sessionUID: baseCredentials.UID))
        XCTAssertNil(sut.authCredential(sessionUID: baseCredentials.UID))
        XCTAssertNil(sut.getCredential(userId: baseCredentials.userID))
    }
}
