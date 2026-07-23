//
// AuthManager.swift
// Proton Pass - Created on 20/11/2023.
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
import Entities
import Foundation
import ProtonCoreAuthentication
import ProtonCoreKeymaker
import ProtonCoreLog
@preconcurrency import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUtilities

public protocol AuthManagerProtocol: Sendable, AuthDelegate {
    var sessionWasInvalidated: AnyPublisher<(sessionId: String, userId: String?), Never> { get }

    func setUp()
    func setUpDelegate(_ delegate: any AuthHelperDelegate)
    func getCredential(userId: String) -> AuthCredential?
    // periphery:ignore
    func clearSessions(sessionId: String)
    // periphery:ignore
    func clearSessions(userId: String)
    func getAllCurrentCredentials() -> [Credential]
    func removeCredentials(userId: String)
    func removeAllCredentials()
    func updateEncryptionDetailsForSession(sessionUID: String,
                                           mailboxpassword: String,
                                           salt: String?,
                                           privateKey: String?)
}

public extension AuthManagerProtocol {
    func isAuthenticated(userId: String) -> Bool {
        guard let credential = getCredential(userId: userId) else {
            return false
        }
        return !credential.isForUnauthenticatedSession
    }
}

/// `@unchecked Sendable` justification: every piece of mutable state lives inside a single
/// `SafeMutex<MutableState>`. The conformance cannot be compiler-checked because ProtonCore's
/// `AuthCredential` (a mutable reference type we are required to vend by `AuthDelegate`) and
/// the delegate protocols carry no `Sendable` annotations. Revisit once ProtonCore ships
/// Swift 6 annotations.
///
/// Locking invariant: public entry points acquire the lock exactly once; private helpers
/// take `inout MutableState` (or a copy) and never lock. `SafeMutex` is non-reentrant —
/// violating this invariant deadlocks, same as the previous `DispatchQueue.sync` design.
/// Delegate callbacks and Combine emissions are computed under the lock but fired after it
/// is released, so delegates/subscribers may safely re-enter the manager.
///
/// Every crossing of a non-Sendable ProtonCore value over the `sending` boundary of
/// `SafeMutex.withLock` goes through `UncheckedSendable` — see its doc comment. When the
/// deployment target reaches iOS 18, `SafeMutex` swaps for `Synchronization.Mutex`
/// unchanged; the boxes stay until ProtonCore annotates its types.
public final class AuthManager: @unchecked Sendable, AuthManagerProtocol {
    public static let storageKey = "AuthManagerStorageKey"

    private typealias CachedCredentials = [CredentialsKey: Credentials]

    private struct MutableState {
        var cachedCredentials: CachedCredentials = [:]
        var didSetUp = false
        /// `false` when the last keychain load failed for a potentially transient reason
        /// (keychain unreadable, symmetric key unavailable). While `false`, persistence is
        /// suppressed so an empty in-memory cache can never overwrite valid stored sessions.
        var storageLoaded = false
        /// Set on first mutation. Blocks late reload attempts that would otherwise
        /// resurrect stale on-disk state over in-memory changes.
        var didMutate = false
        weak var delegate: (any AuthHelperDelegate)?
        weak var loginAndSignupDelegate: (any AuthSessionInvalidatedDelegate)?
    }

    /// Carries non-Sendable ProtonCore values across `SafeMutex.withLock`'s `sending`
    /// boundaries, in both directions:
    /// - Outbound: results derived from the protected state (`AuthCredential`, `Credential`,
    ///   notification closures capturing delegates) are not in a disconnected region, so
    ///   region analysis rejects returning them directly. Note this is the same shared
    ///   mutable `AuthCredential` hand-out the pre-refactor code (and ProtonCore's own
    ///   `AuthHelper`) performed — the box documents it rather than introducing it.
    /// - Inbound: assigning caller-region values (delegates, `Credential` parameters) into
    ///   the protected state trips the swiftlang/swift#77199 / #81546 rejections noted on
    ///   `SafeMutex`; boxing before the lock sidesteps them deterministically.
    /// Safe: each box is created and consumed synchronously on the calling thread; the
    /// contained value is only ever touched on one side of the lock at a time.
    private struct UncheckedSendable<Value>: @unchecked Sendable {
        let value: Value

        init(_ value: Value) {
            self.value = value
        }
    }

    private let state = SafeMutex(MutableState())
    private let keychain: any KeychainProtocol
    private let symmetricKeyProvider: any NonAsyncSymmetricKeyProvider
    private let module: PassModule
    private let logger: Logger
    private let sessionInvalidationSubject =
        PassthroughSubject<(sessionId: String, userId: String?), Never>()

    public var sessionWasInvalidated: AnyPublisher<(sessionId: String, userId: String?), Never> {
        sessionInvalidationSubject.eraseToAnyPublisher()
    }

    // swiftlint:disable:next identifier_name
    public var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)? {
        get { state.withLock { UncheckedSendable($0.loginAndSignupDelegate) }.value }
        set {
            let incoming = UncheckedSendable(newValue)
            state.withLock { $0.loginAndSignupDelegate = incoming.value }
        }
    }

    public init(keychain: any KeychainProtocol,
                symmetricKeyProvider: any NonAsyncSymmetricKeyProvider,
                module: PassModule,
                logManager: any LogManagerProtocol) {
        self.keychain = keychain
        self.symmetricKeyProvider = symmetricKeyProvider
        self.module = module
        logger = .init(manager: logManager)
    }

    public func setUp() {
        state.withLock { state in
            guard !state.didSetUp else { return } // idempotent; was previously a silent reload
            loadFromKeychain(into: &state)
            state.didSetUp = true
        }
    }

    public func setUpDelegate(_ delegate: any AuthHelperDelegate) {
        let incoming = UncheckedSendable(delegate)
        state.withLock { state in
            assertDidSetUp(state)
            state.delegate = incoming.value
        }
    }

    public func getCredential(userId: String) -> AuthCredential? {
        logger.info("Getting authCredential for user id \(userId)")
        return state.withLock { state -> UncheckedSendable<AuthCredential?> in
            ensureLoaded(&state)
            let credential = state.cachedCredentials
                .first { $0.key.module == module && $0.value.authCredential.userID == userId }?
                .value.authCredential
            return UncheckedSendable(credential)
        }.value
    }

    public func credential(sessionUID: String) -> Credential? {
        logger.info("Getting credential for session id \(sessionUID)")
        return state.withLock { state -> UncheckedSendable<Credential?> in
            ensureLoaded(&state)
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            return UncheckedSendable(state.cachedCredentials[key]?.credential)
        }.value
    }

    public func authCredential(sessionUID: String) -> AuthCredential? {
        logger.info("Getting authCredential for session id \(sessionUID)")
        return state.withLock { state -> UncheckedSendable<AuthCredential?> in
            ensureLoaded(&state)
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            return UncheckedSendable(state.cachedCredentials[key]?.authCredential)
        }.value
    }

    public func removeCredentials(userId: String) {
        logger.info("Removing credentials for user id \(userId)")
        state.withLock { state in
            ensureLoaded(&state)
            state.didMutate = true
            state.cachedCredentials = state.cachedCredentials
                .filter { $0.value.credential.userID != userId }
            persist(state)
        }
    }

    public func removeAllCredentials() {
        state.withLock { state in
            ensureLoaded(&state)
            state.didMutate = true
            state.cachedCredentials = [:]
            persist(state)
        }
    }

    public func updateEncryptionDetailsForSession(sessionUID: String,
                                                  mailboxpassword: String,
                                                  salt: String?,
                                                  privateKey: String?) {
        onAdditionalCredentialsInfoObtained(sessionUID: sessionUID,
                                            password: mailboxpassword,
                                            salt: salt,
                                            privateKey: privateKey)
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
        logger.info("Updating session credentials for session id \(sessionUID)")
        let incoming = UncheckedSendable(credential)
        let notification = state.withLock { state -> UncheckedSendable<() -> Void>? in
            let credential = incoming.value
            ensureLoaded(&state)
            state.didMutate = true
            for passModule in PassModule.allCases {
                let key = CredentialsKey(sessionId: sessionUID, module: passModule)
                // `Credential.mailboxpassword` is empty here; fall back to the cached entry
                // and merge so the stored password/key data survives the update.
                let existing = state.cachedCredentials[key]
                    ?? Credentials(credential: credential,
                                   authCredential: AuthCredential(credential),
                                   module: passModule)
                let newAuthCredential = existing.authCredential
                    .updatedKeepingKeyAndPasswordDataIntact(credential: credential)
                state.cachedCredentials[key] = Credentials(credential: credential,
                                                           authCredential: newAuthCredential,
                                                           module: passModule)
            }
            persist(state)
            return credentialsUpdateNotification(state, sessionId: sessionUID)
        }
        notification?.value()
    }

    public func onSessionObtaining(credential: Credential) {
        logger.info("Obtained session credentials for session id \(credential.UID)")
        let incoming = UncheckedSendable(credential)
        let notification = state.withLock { state -> UncheckedSendable<() -> Void>? in
            let credential = incoming.value
            ensureLoaded(&state)
            state.didMutate = true
            // Logging into the same account again: drop all prior sessions for that user.
            for (key, value) in state.cachedCredentials
                where value.credential.userID == credential.userID {
                state.cachedCredentials.removeValue(forKey: key)
            }
            for passModule in PassModule.allCases {
                let key = CredentialsKey(sessionId: credential.UID, module: passModule)
                state.cachedCredentials[key] = Credentials(credential: credential,
                                                           authCredential: AuthCredential(credential),
                                                           module: passModule)
            }
            persist(state)
            return credentialsUpdateNotification(state, sessionId: credential.UID)
        }
        notification?.value()
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {
        logger.info("Additional credentials for session id \(sessionUID)")
        let notification = state.withLock { state -> UncheckedSendable<() -> Void>? in
            ensureLoaded(&state)
            state.didMutate = true
            for passModule in PassModule.allCases {
                let key = CredentialsKey(sessionId: sessionUID, module: passModule)
                // `continue`, not `return`: a missing module entry must not abort the
                // remaining modules or skip persistence/notification.
                guard let element = state.cachedCredentials[key] else { continue }

                if let password {
                    element.authCredential.update(password: password)
                }
                let saltToUpdate = salt ?? element.authCredential.passwordKeySalt
                let privateKeyToUpdate = privateKey ?? element.authCredential.privateKey
                element.authCredential.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
                state.cachedCredentials[key] = element
            }
            persist(state)
            return credentialsUpdateNotification(state, sessionId: sessionUID)
        }
        notification?.value()
    }

    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
        logger.info("Authenticated session invalidated for session id \(sessionUID)")
        invalidateSession(sessionUID: sessionUID, isAuthenticatedSession: true)
    }

    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
        logger.info("Unauthenticated session invalidated for session id \(sessionUID)")
        invalidateSession(sessionUID: sessionUID, isAuthenticatedSession: false)
    }

    public func clearSessions(sessionId: String) {
        logger.info("Clearing sessions for session id \(sessionId)")
        state.withLock { state in
            ensureLoaded(&state)
            state.didMutate = true
            removeCredentials(for: sessionId, in: &state)
            persist(state)
        }
    }

    public func clearSessions(userId: String) {
        logger.info("Clearing sessions for user id \(userId)")
        state.withLock { state in
            ensureLoaded(&state)
            state.didMutate = true
            state.cachedCredentials = state.cachedCredentials
                .filter { $0.value.credential.userID != userId }
            persist(state)
        }
    }

    public func getAllCurrentCredentials() -> [Credential] {
        state.withLock { state -> UncheckedSendable<[Credential]> in
            ensureLoaded(&state)
            let credentials = state.cachedCredentials.compactMap { key, element in
                key.module == module ? element.credential : nil
            }
            return UncheckedSendable(credentials)
        }.value
    }
}

public extension AuthManager {
    /// Introduced on February 2025 for CSV import support. Can be removed later on.
    func initializeCredentialsForActionExtension() {
        state.withLock { state in
            ensureLoaded(&state)
            state.didMutate = true
            if let appCredential = state.cachedCredentials.first(where: { $0.key.module == .hostApp }) {
                let key = CredentialsKey(sessionId: appCredential.value.authCredential.sessionID,
                                         module: .actionExtension)
                state.cachedCredentials[key] = appCredential.value
            }
            persist(state)
        }
    }

    @_spi(QA)
    func getAllCredentialsOfAllModules() -> [Credentials] {
        // `Credentials` is declared Sendable, so no box is needed here.
        state.withLock { state in
            ensureLoaded(&state)
            return Array(state.cachedCredentials.values)
        }
    }
}

// MARK: - Private helpers (never lock — callers hold the lock)

private extension AuthManager {
    private func invalidateSession(sessionUID: String, isAuthenticatedSession: Bool) {
        let notification = state.withLock { state -> UncheckedSendable<() -> Void> in
            ensureLoaded(&state)
            state.didMutate = true
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            let userId = state.cachedCredentials[key]?.credential.userID
            removeCredentials(for: sessionUID, in: &state)
            persist(state)
            return sessionInvalidationNotification(state,
                                                   sessionId: sessionUID,
                                                   userId: userId,
                                                   isAuthenticatedSession: isAuthenticatedSession)
        }
        notification.value()
    }

    private func ensureLoaded(_ state: inout MutableState) {
        assertDidSetUp(state)
        // Lazy recovery from a transient load failure (e.g. extension launched before the
        // keychain/symmetric key became available). Only safe while nothing has mutated.
        if state.didSetUp, !state.storageLoaded, !state.didMutate {
            loadFromKeychain(into: &state)
        }
    }

    private func assertDidSetUp(_ state: MutableState) {
        assert(state.didSetUp, "AuthManager not set up. Call setUp() as soon as possible.")
        if !state.didSetUp {
            logger.error("AuthManager not set up")
        }
    }

    private func removeCredentials(for sessionUID: String, in state: inout MutableState) {
        for module in PassModule.allCases {
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            state.cachedCredentials[key] = nil
        }
    }

    private func credentialsUpdateNotification(_ state: MutableState,
                                               sessionId: String) -> UncheckedSendable<() -> Void>? {
        let key = CredentialsKey(sessionId: sessionId, module: module)
        guard let credentials = state.cachedCredentials[key],
              let delegate = state.delegate else {
            return nil
        }
        return UncheckedSendable {
            delegate.credentialsWereUpdated(authCredential: credentials.authCredential,
                                            credential: credentials.credential,
                                            for: sessionId)
        }
    }

    private func sessionInvalidationNotification(_ state: MutableState,
                                                 sessionId: String,
                                                 userId: String?,
                                                 isAuthenticatedSession: Bool)
        -> UncheckedSendable<() -> Void> {
        let delegate = state.delegate
        let loginAndSignupDelegate = state.loginAndSignupDelegate
        let subject = sessionInvalidationSubject
        return UncheckedSendable {
            delegate?.sessionWasInvalidated(for: sessionId,
                                            isAuthenticatedSession: isAuthenticatedSession)
            loginAndSignupDelegate?.sessionWasInvalidated(for: sessionId,
                                                          isAuthenticatedSession: isAuthenticatedSession)
            subject.send((sessionId: sessionId, userId: userId))
        }
    }
}

// MARK: - Storage (callers hold the lock)

private extension AuthManager {
    private func loadFromKeychain(into state: inout MutableState) {
        let encrypted: Data?
        do {
            encrypted = try keychain.dataOrError(forKey: Self.storageKey)
        } catch {
            // Transient (e.g. data protection / device locked): keep the stored blob,
            // suppress persistence until a successful load.
            logger.error("Failed to read stored sessions from keychain, will retry: \(error)")
            state.storageLoaded = false
            return
        }

        guard let encrypted else {
            // Nothing stored: first run or post-wipe.
            state.cachedCredentials = [:]
            state.storageLoaded = true
            return
        }

        do {
            let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
            do {
                let decrypted = try symmetricKey.decrypt(encrypted)
                state.cachedCredentials = try JSONDecoder()
                    .decode(CachedCredentials.self, from: decrypted)
                state.storageLoaded = true
            } catch {
                // Key is available but the payload doesn't decrypt/decode: unrecoverable
                // corruption or a rotated key. Wipe, as the previous implementation did.
                logger.error("Failed to decrypt stored sessions, wiping: \(error)")
                try? keychain.removeOrError(forKey: Self.storageKey)
                state.cachedCredentials = [:]
                state.storageLoaded = true
            }
        } catch {
            // Symmetric key unavailable (assumed transient, e.g. keymaker not unlocked yet).
            logger.error("Symmetric key unavailable, keeping stored sessions: \(error)")
            state.storageLoaded = false
        }
    }

    private func persist(_ state: MutableState) {
        guard state.storageLoaded else {
            // Never overwrite a keychain blob we could not read: with a failed load the
            // in-memory cache is a strict subset of reality and saving it would log out
            // every stored user.
            logger.error("Skipping session persistence: stored sessions were never loaded")
            return
        }
        do {
            let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
            let data = try JSONEncoder().encode(state.cachedCredentials)
            let encryptedContent = try symmetricKey.encrypt(data)
            try keychain.setOrError(encryptedContent, forKey: Self.storageKey)
        } catch {
            logger.error("Failed to save user sessions in keychain: \(error)")
        }
    }
}

// MARK: - Keychain codable wrappers for credential elements & extensions

public struct Credentials: Hashable, Sendable, Codable {
    public let credential: Credential
    public let authCredential: AuthCredential
    public let module: PassModule
}

struct CredentialsKey: Hashable, Codable {
    let sessionId: String
    let module: PassModule
}

extension Credential: @retroactive Codable, @retroactive Hashable {
    private enum CodingKeys: String, CodingKey {
        case UID
        case accessToken
        case refreshToken
        case userName
        case userID
        case scopes
        case mailboxPassword
        case isCredentialLess
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(UID)
        hasher.combine(accessToken)
        hasher.combine(refreshToken)
        hasher.combine(userName)
        hasher.combine(userID)
        hasher.combine(scopes)
        hasher.combine(mailboxPassword)
        hasher.combine(isCredentialLess)
    }

    public init(from decoder: any Decoder) throws {
        self.init(UID: "",
                  accessToken: "",
                  refreshToken: "",
                  userName: "",
                  userID: "",
                  scopes: [],
                  mailboxPassword: "",
                  isCredentialLess: false)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        UID = try values.decode(String.self, forKey: .UID)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        refreshToken = try values.decode(String.self, forKey: .refreshToken)
        userName = try values.decode(String.self, forKey: .userName)
        userID = try values.decode(String.self, forKey: .userID)
        scopes = try values.decode([String].self, forKey: .scopes)
        mailboxPassword = try values.decode(String.self, forKey: .mailboxPassword)
        isCredentialLess = try values.decodeIfPresent(Bool.self, forKey: .isCredentialLess) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(UID, forKey: .UID)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(userName, forKey: .userName)
        try container.encode(userID, forKey: .userID)
        try container.encode(scopes, forKey: .scopes)
        try container.encode(mailboxPassword, forKey: .mailboxPassword)
        try container.encode(isCredentialLess, forKey: .isCredentialLess)
    }
}
