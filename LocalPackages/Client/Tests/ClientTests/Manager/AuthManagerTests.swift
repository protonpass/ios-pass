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

/// Named payloads instead of tuples: `AuthHelperDelegate` hands over three values at once, which
/// is one past SwiftLint's `large_tuple` threshold.
struct CredentialsUpdate {
    let authCredential: ProtonCoreNetworking.AuthCredential
    let credential: ProtonCoreNetworking.Credential
    let sessionUID: String
}

struct SessionInvalidation {
    let sessionUID: String
    let isAuthenticatedSession: Bool
}

/// `@unchecked Sendable`: ProtonCore's `AuthHelperDelegate` carries no `Sendable` annotation and
/// `PassthroughSubject` is not `Sendable`. Each suite instance uses its own mock from a single
/// task, so there is no concurrent access to check.
final class AuthHelperDelegateMock: @unchecked Sendable, AuthHelperDelegate {
    let credentialsWereUpdatedSubject = PassthroughSubject<CredentialsUpdate, Never>()
    let sessionWasInvalidatedSubject = PassthroughSubject<SessionInvalidation, Never>()

    func credentialsWereUpdated(authCredential: ProtonCoreNetworking.AuthCredential,
                                credential: ProtonCoreNetworking.Credential,
                                for sessionUID: String) {
        credentialsWereUpdatedSubject.send(.init(authCredential: authCredential,
                                                 credential: credential,
                                                 sessionUID: sessionUID))
    }

    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        sessionWasInvalidatedSubject.send(.init(sessionUID: sessionUID,
                                                isAuthenticatedSession: isAuthenticatedSession))
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

    private let symmetricKeyProvider: NonSendableSymmetricKeyProviderMock
    /// Every `AuthManager` persists under the same `AuthManager.storageKey`, so each suite instance
    /// gets its own keychain — sharing one would let the parallel tests overwrite each other's
    /// sessions. In-memory, so there is nothing to tear down, matching how the datasource suites
    /// use `DatabaseService(inMemory: true)`.
    private let keychain = InMemoryKeychainMock()
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

        self.symmetricKeyProvider = symmetricKeyProvider
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
        #expect(sut.authCredential(sessionUID: baseCredentials.UID)?.mailboxpassword.isEmpty == true)

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

        let newToken = rotated(accessToken: "rotated_access_token")
        autoFillSut.onUpdate(credential: newToken, sessionUID: baseCredentials.UID)

        // The host app still holds the pre-rotation token in memory.
        #expect(sut.credential(sessionUID: baseCredentials.UID)?.accessToken == baseCredentials.accessToken)

        sut.setUp()

        #expect(sut.credential(sessionUID: baseCredentials.UID)?.accessToken == newToken.accessToken)
        #expect(sut.getCredential(userId: baseCredentials.userID)?.accessToken == newToken.accessToken)
    }

    /// The other half of the guard: when a mutation never reached the keychain the in-memory
    /// cache is the fresher copy, so reloading must not throw away a live token.
    @Test func `setUp keeps unpersisted credentials`() {
        sut.onSessionObtaining(credential: baseCredentials)

        let updated = rotated(accessToken: "unpersisted_access_token")

        // Make persistence fail, so the update lands in memory only.
        symmetricKeyProvider.getSymmetricKeyThrowableError1 = SymmetricKeyUnavailable()
        sut.onUpdate(credential: updated, sessionUID: baseCredentials.UID)
        symmetricKeyProvider.getSymmetricKeyThrowableError1 = nil

        sut.setUp()

        #expect(sut.credential(sessionUID: baseCredentials.UID)?.accessToken == updated.accessToken)
    }

    /// Regression: skipping the reload whenever anything was unpersisted was unrecoverable.
    /// `persist` needs `storageLoaded`, and `storageLoaded` only flips on a successful read, so a
    /// mutation during a read failure suppressed persistence for the rest of the process — every
    /// token refreshed afterwards was lost, and the next launch presented a stale refresh token.
    @Test func `a mutation during a keychain read failure is persisted once the keychain recovers`() {
        // A read failure (device locked, symmetric key not yet available) leaves the manager
        // unable to persist...
        keychain.readError = KeychainUnreadable()
        sut.setUp()

        // ...so this session exists in memory only.
        sut.onSessionObtaining(credential: baseCredentials)
        #expect(sut.credential(sessionUID: baseCredentials.UID)?.UID == baseCredentials.UID)

        // The keychain recovers. The next reload must retry, merge memory over what it reads and
        // flush — not refuse to reload forever.
        keychain.readError = nil
        sut.setUp()

        // Proven by a manager that shares only the keychain: the session really reached storage.
        let fresh = AuthManager(keychain: keychain,
                                symmetricKeyProvider: symmetricKeyProvider,
                                module: .hostApp,
                                logManager: LogManagerProtocolMock())
        fresh.setUp()
        #expect(fresh.credential(sessionUID: baseCredentials.UID)?.UID == baseCredentials.UID)
    }

    /// Once the recovery flush has happened the manager is back to normal: a later rotation by
    /// another module is picked up again, i.e. `hasUnpersistedChanges` really was cleared.
    @Test func `reloading resumes after a failed write is flushed`() {
        sut.onSessionObtaining(credential: baseCredentials)

        // A failed write marks the cache as unpersisted...
        symmetricKeyProvider.getSymmetricKeyThrowableError1 = SymmetricKeyUnavailable()
        sut.onUpdate(credential: rotated(accessToken: "unpersisted"), sessionUID: baseCredentials.UID)
        symmetricKeyProvider.getSymmetricKeyThrowableError1 = nil

        // ...which the next reload resolves by flushing it.
        sut.setUp()

        // From here reloads work again, so another module's rotation lands.
        let autoFillSut = AuthManager(keychain: keychain,
                                      symmetricKeyProvider: symmetricKeyProvider,
                                      module: .autoFillExtension,
                                      logManager: LogManagerProtocolMock())
        autoFillSut.setUp()
        let newToken = rotated(accessToken: "rotated_after_recovery")
        autoFillSut.onUpdate(credential: newToken, sessionUID: baseCredentials.UID)

        sut.setUp()

        #expect(sut.credential(sessionUID: baseCredentials.UID)?.accessToken == newToken.accessToken)
    }

    /// Another module wiping the shared keychain reaches us as a silent cache shrink rather than a
    /// session invalidation, so the reload has to surface it — the UI otherwise stays logged in
    /// with no credentials and the only symptom is blanket 401s.
    @Test func `setUp drops sessions wiped by another module`() {
        sut.onSessionObtaining(credential: baseCredentials)
        #expect(sut.getCredential(userId: baseCredentials.userID) != nil)

        try? keychain.removeOrError(forKey: AuthManager.storageKey)
        sut.setUp()

        #expect(sut.credential(sessionUID: baseCredentials.UID) == nil)
        #expect(sut.getCredential(userId: baseCredentials.userID) == nil)
    }
}

// MARK: - Helpers

private extension AuthManagerTests {
    struct SymmetricKeyUnavailable: Error {}
    struct KeychainUnreadable: Error {}

    /// `baseCredentials` with a different access & refresh token, i.e. the same session after the
    /// backend rotated it.
    func rotated(accessToken: String) -> Credential {
        Credential(UID: baseCredentials.UID,
                   accessToken: accessToken,
                   refreshToken: "refresh_for_\(accessToken)",
                   userName: baseCredentials.userName,
                   userID: baseCredentials.userID,
                   scopes: [],
                   mailboxPassword: "")
    }
}
