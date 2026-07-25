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

@testable import Client
import ClientMocks
import Combine
import Core
import CoreMocks
import CryptoKit
import Entities
import Foundation
import ProtonCoreAuthentication
import ProtonCoreCryptoGoImplementation
@preconcurrency import ProtonCoreNetworking
import Testing

/// `@unchecked Sendable`: ProtonCore's `AuthHelperDelegate` carries no `Sendable` annotation and
/// `PassthroughSubject` is not `Sendable`. Each suite instance uses its own mock from a single
/// task, so there is no concurrent access to check.
final class AuthHelperDelegateMock: @unchecked Sendable, AuthHelperDelegate {
    let credentialsWereUpdatedSubject: PassthroughSubject<(authCredential: ProtonCoreNetworking.AuthCredential,
                                                           credential: ProtonCoreNetworking.Credential,
                                                           sessionUID: String), Never> = .init()
    let sessionWasInvalidatedSubject: PassthroughSubject<(sessionUID: String,
                                                          isAuthenticatedSession: Bool), Never> = .init()

    func credentialsWereUpdated(authCredential: ProtonCoreNetworking.AuthCredential,
                                credential: ProtonCoreNetworking.Credential,
                                for sessionUID: String) {
        credentialsWereUpdatedSubject.send((authCredential, credential, sessionUID))
    }

    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        sessionWasInvalidatedSubject.send((sessionUID, isAuthenticatedSession))
    }
}

@Suite(.tags(.manager))
struct AuthManagerTests {
    /// `static` so the global crypto implementation is installed exactly once: unlike XCTest,
    /// Swift Testing runs the tests in this suite in parallel.
    private static let cryptoIsInstalled: Bool = {
        injectDefaultCryptoImplementation()
        return true
    }()

    /// Every `AuthManager` persists under the same `AuthManager.storageKey`, so each suite
    /// instance gets its own `UserDefaults` domain. Sharing one would let the parallel tests
    /// overwrite each other's sessions; isolating also means no teardown is needed, matching
    /// how the datasource suites use `DatabaseService(inMemory: true)`.
    private static func isolatedDefaults() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: "AuthManagerTests-\(UUID().uuidString)") else {
            fatalError("Could not create an isolated UserDefaults suite")
        }
        return defaults
    }

    private let symmetricKeyProvider: NonSendableSymmetricKeyProviderMock
    private let keychain: UserDefaultsKeychainMock
    private let authHelperDelegateMock = AuthHelperDelegateMock()
    private let sut: AuthManager

    private let baseCredentials = Credential(UID: "test_session_id",
                                             accessToken: "test_access_token_unauth",
                                             refreshToken: "test_refresh_token_unauth",
                                             userName: "test_user_name",
                                             userID: "test_user_id",
                                             scopes: [],
                                             mailboxPassword: "")

    init() {
        _ = Self.cryptoIsInstalled

        let symmetricKeyProvider = NonSendableSymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = SymmetricKey.random()
        let keychain = UserDefaultsKeychainMock(userDefaults: Self.isolatedDefaults())

        self.symmetricKeyProvider = symmetricKeyProvider
        self.keychain = keychain
        sut = AuthManager(keychain: keychain,
                          symmetricKeyProvider: symmetricKeyProvider,
                          module: .hostApp,
                          logManager: LogManagerProtocolMock())
        sut.setUp()
    }

    @Test func `no credential is returned when nothing is persisted`() {
        #expect(sut.getCredential(userId: baseCredentials.userID) == nil)
    }

    @Test func `an obtained session is readable by session id and by user id`() {
        sut.onSessionObtaining(credential: baseCredentials)

        #expect(sut.credential(sessionUID: baseCredentials.UID)?.UID == baseCredentials.UID)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.sessionID == baseCredentials.UID)
        #expect(sut.getCredential(userId: baseCredentials.userID)?.sessionID == baseCredentials.UID)
    }

    @Test func `updating a session replaces the stored user name`() {
        sut.onSessionObtaining(credential: baseCredentials)

        let newCredentials = Credential(UID: baseCredentials.UID,
                                        accessToken: "test_access_token_unauth",
                                        refreshToken: "test_refresh_token_unauth",
                                        userName: "new_test_user_name",
                                        userID: baseCredentials.userID,
                                        scopes: [],
                                        mailboxPassword: "")

        sut.onUpdate(credential: newCredentials, sessionUID: baseCredentials.UID)

        #expect(sut.credential(sessionUID: baseCredentials.UID)?.userName == newCredentials.userName)
        #expect(sut.getCredential(userId: baseCredentials.userID)?.userName == newCredentials.userName)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.userName == newCredentials.userName)
    }

    /// The delegate is notified synchronously from `onAdditionalCredentialsInfoObtained`, so the
    /// event is recorded and then required — no expectation or timeout involved.
    @Test func `additional credentials info is stored and notified`() throws {
        sut.onSessionObtaining(credential: baseCredentials)

        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.passwordKeySalt == nil)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.privateKey == nil)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.mailboxpassword == "")

        sut.setUpDelegate(authHelperDelegateMock)

        let newSalt = "salttest"
        let newPrivateKey = "privatekeytest"
        let newPassword = "test"

        var cancellables = Set<AnyCancellable>()
        var notified: ProtonCoreNetworking.AuthCredential?
        authHelperDelegateMock.credentialsWereUpdatedSubject
            .sink { notified = $0.authCredential }
            .store(in: &cancellables)

        sut.onAdditionalCredentialsInfoObtained(sessionUID: baseCredentials.UID,
                                                password: newPassword,
                                                salt: newSalt,
                                                privateKey: newPrivateKey)

        let notifiedCredential = try #require(notified, "credentialsWereUpdated was never called")
        #expect(notifiedCredential.passwordKeySalt == newSalt)
        #expect(notifiedCredential.privateKey == newPrivateKey)
        #expect(notifiedCredential.mailboxpassword == newPassword)

        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.passwordKeySalt == newSalt)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.privateKey == newPrivateKey)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.mailboxpassword == newPassword)
    }

    /// Both invalidation paths clear the session, notify the delegate and emit on
    /// `sessionWasInvalidated`; only the `isAuthenticatedSession` flag differs.
    @Test(arguments: [true, false])
    func `invalidating a session clears it and notifies observers`(isAuthenticatedSession: Bool) throws {
        sut.onSessionObtaining(credential: baseCredentials)
        sut.setUpDelegate(authHelperDelegateMock)

        var cancellables = Set<AnyCancellable>()
        var delegateEvent: (sessionUID: String, isAuthenticatedSession: Bool)?
        var publishedEvent: (sessionId: String, userId: String?)?
        authHelperDelegateMock.sessionWasInvalidatedSubject
            .sink { delegateEvent = $0 }
            .store(in: &cancellables)
        sut.sessionWasInvalidated
            .sink { publishedEvent = $0 }
            .store(in: &cancellables)

        if isAuthenticatedSession {
            sut.onAuthenticatedSessionInvalidated(sessionUID: baseCredentials.UID)
        } else {
            sut.onUnauthenticatedSessionInvalidated(sessionUID: baseCredentials.UID)
        }

        let delegated = try #require(delegateEvent, "sessionWasInvalidated delegate was never called")
        #expect(delegated.sessionUID == baseCredentials.UID)
        #expect(delegated.isAuthenticatedSession == isAuthenticatedSession)

        let published = try #require(publishedEvent, "sessionWasInvalidated never emitted")
        #expect(published.sessionId == baseCredentials.UID)
        #expect(published.userId == baseCredentials.userID)

        #expect(sut.credential(sessionUID: baseCredentials.UID) == nil)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID) == nil)
        #expect(sut.getCredential(userId: baseCredentials.userID) == nil)
    }

    @Test func `clearing sessions by session id removes the credentials`() {
        sut.onSessionObtaining(credential: baseCredentials)
        #expect(sut.credential(sessionUID: baseCredentials.UID)?.UID == baseCredentials.UID)

        sut.clearSessions(sessionId: baseCredentials.UID)

        #expect(sut.credential(sessionUID: baseCredentials.UID) == nil)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID) == nil)
        #expect(sut.getCredential(userId: baseCredentials.userID) == nil)
    }

    @Test func `clearing sessions by user id removes the credentials`() {
        sut.onSessionObtaining(credential: baseCredentials)
        #expect(sut.getCredential(userId: baseCredentials.userID)?.sessionID == baseCredentials.UID)

        sut.clearSessions(userId: baseCredentials.userID)

        #expect(sut.credential(sessionUID: baseCredentials.UID) == nil)
        #expect(sut.authCredential(sessionUID: baseCredentials.UID) == nil)
        #expect(sut.getCredential(userId: baseCredentials.userID) == nil)
    }

    /// `setUp()` is re-run on every foreground so the app picks up tokens an extension rotated
    /// in the shared keychain. If it no-ops, the app keeps a stale refresh token and the
    /// backend answers 400/422, which the app turns into a spurious logout.
    @Test func `setUp reloads credentials rotated by another module`() {
        sut.onSessionObtaining(credential: baseCredentials)

        // Same keychain & key, different module: this is AutoFill refreshing the session.
        let autoFillSut = AuthManager(keychain: keychain,
                                      symmetricKeyProvider: symmetricKeyProvider,
                                      module: .autoFillExtension,
                                      logManager: LogManagerProtocolMock())
        autoFillSut.setUp()

        let rotated = Credential(UID: baseCredentials.UID,
                                 accessToken: "rotated_access_token",
                                 refreshToken: "rotated_refresh_token",
                                 userName: baseCredentials.userName,
                                 userID: baseCredentials.userID,
                                 scopes: [],
                                 mailboxPassword: "")
        autoFillSut.onUpdate(credential: rotated, sessionUID: baseCredentials.UID)

        // The host app still holds the pre-rotation token in memory.
        #expect(sut.credential(sessionUID: baseCredentials.UID)?.accessToken == baseCredentials.accessToken)

        sut.setUp()

        #expect(sut.credential(sessionUID: baseCredentials.UID)?.accessToken == rotated.accessToken)
        #expect(sut.getCredential(userId: baseCredentials.userID)?.accessToken == rotated.accessToken)
    }

    /// The other half of the guard: when a mutation never reached the keychain the in-memory
    /// cache is the fresher copy, so reloading would throw away a live token.
    @Test func `setUp keeps unpersisted credentials`() {
        struct SymmetricKeyUnavailable: Error {}

        sut.onSessionObtaining(credential: baseCredentials)

        let updated = Credential(UID: baseCredentials.UID,
                                 accessToken: "unpersisted_access_token",
                                 refreshToken: "unpersisted_refresh_token",
                                 userName: baseCredentials.userName,
                                 userID: baseCredentials.userID,
                                 scopes: [],
                                 mailboxPassword: "")

        // Make persistence fail, so the update lands in memory only.
        symmetricKeyProvider.getSymmetricKeyThrowableError1 = SymmetricKeyUnavailable()
        sut.onUpdate(credential: updated, sessionUID: baseCredentials.UID)
        symmetricKeyProvider.getSymmetricKeyThrowableError1 = nil

        sut.setUp()

        #expect(sut.credential(sessionUID: baseCredentials.UID)?.accessToken == updated.accessToken)
    }
}
