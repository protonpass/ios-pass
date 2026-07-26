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
/// Locking invariant: public entry points acquire the lock exactly once — as does the one
/// private helper they share, `invalidateSession` — and every other private helper takes
/// `inout MutableState` (or a copy) and never locks. `SafeMutex` is non-reentrant —
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
        /// `true` when the in-memory cache holds mutations that never reached the keychain
        /// (persistence skipped because `storageLoaded` was `false`, or the keychain write
        /// failed). Only then is the keychain staler than memory, so only then does a reload
        /// merge the cache back over what it read instead of replacing it — a plain replace
        /// would silently drop a freshly refreshed token and log the user out. See `apply`.
        /// Cleared by the next successful `persist`.
        var hasUnpersistedChanges = false
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

    /// Loads the stored sessions, and is deliberately **not** idempotent: the keychain is shared
    /// across the app group, so extensions rotate and clear tokens behind our back. The app
    /// re-runs this on every foreground (see `HomepageCoordinator`) precisely to pick that up —
    /// skipping the reload leaves a stale refresh token in memory, which the backend rejects with
    /// 400/422 and turns into a spurious logout.
    ///
    /// The keychain read, decryption and decoding happen *before* taking the lock: `SafeMutex` is
    /// backed by `os_unfair_lock`, which is meant for short critical sections, and this runs on
    /// the caller's actor — the `MainActor` on every foreground, via `SetUpBeforeLaunching`.
    /// Only the decoded result is swapped in under the lock. `persist` and the `ensureLoaded`
    /// retry cannot do the same — they are reached from the synchronous `AuthDelegate` callbacks —
    /// so those do hold the lock across keychain I/O and crypto.
    public func setUp() {
        let outcome = readFromKeychain(logFailure: true)
        state.withLock { state in
            state.didSetUp = true
            apply(outcome, to: &state)
        }
    }

    public func setUpDelegate(_ delegate: any AuthHelperDelegate) {
        let incoming = UncheckedSendable(delegate)
        state.withLock { state in
            assertDidSetUp(state)
            state.delegate = incoming.value
        }
    }

    /// Lookups are hot paths called several times per request, so only misses are logged:
    /// a hit says nothing, a miss is what turns into a 401 "Invalid access token" downstream.
    ///
    /// A miss on an *empty* id is not a miss at all — callers use `""` to mean "no active user",
    /// i.e. deliberately unauthenticated (see `RefreshFeatureFlags`). Warning there would fire on
    /// every pre-login request and evict the entries that matter, `LogManagerConfig.maxLogLines`
    /// being 5 000.
    public func getCredential(userId: String) -> AuthCredential? {
        let credential = state.withLock { state -> UncheckedSendable<AuthCredential?> in
            ensureLoaded(&state)
            let credential = state.cachedCredentials
                .first { $0.key.module == module && $0.value.authCredential.userID == userId }?
                .value.authCredential
            return UncheckedSendable(credential)
        }.value
        if credential == nil, !userId.isEmpty {
            logger.warning("No authCredential for user id \(userId)")
        }
        return credential
    }

    public func credential(sessionUID: String) -> Credential? {
        let credential = state.withLock { state -> UncheckedSendable<Credential?> in
            ensureLoaded(&state)
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            return UncheckedSendable(state.cachedCredentials[key]?.credential)
        }.value
        if credential == nil, !sessionUID.isEmpty {
            logger.warning("No credential for session id \(sessionUID)")
        }
        return credential
    }

    public func authCredential(sessionUID: String) -> AuthCredential? {
        let credential = state.withLock { state -> UncheckedSendable<AuthCredential?> in
            ensureLoaded(&state)
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            return UncheckedSendable(state.cachedCredentials[key]?.authCredential)
        }.value
        if credential == nil, !sessionUID.isEmpty {
            logger.warning("No authCredential for session id \(sessionUID)")
        }
        return credential
    }

    public func removeCredentials(userId: String) {
        logger.info("Removing credentials for user id \(userId)")
        state.withLock { state in
            ensureLoaded(&state)
            state.cachedCredentials = state.cachedCredentials
                .filter { $0.value.credential.userID != userId }
            persist(&state)
        }
    }

    public func removeAllCredentials() {
        state.withLock { state in
            ensureLoaded(&state)
            state.cachedCredentials = [:]
            persist(&state)
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
            persist(&state)
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
            persist(&state)
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
            persist(&state)
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
            removeCredentials(for: sessionId, in: &state)
            persist(&state)
        }
    }

    public func clearSessions(userId: String) {
        logger.info("Clearing sessions for user id \(userId)")
        state.withLock { state in
            ensureLoaded(&state)
            state.cachedCredentials = state.cachedCredentials
                .filter { $0.value.credential.userID != userId }
            persist(&state)
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
            if let appCredential = state.cachedCredentials.first(where: { $0.key.module == .hostApp }) {
                let key = CredentialsKey(sessionId: appCredential.value.authCredential.sessionID,
                                         module: .actionExtension)
                state.cachedCredentials[key] = appCredential.value
            }
            persist(&state)
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

// MARK: - Private helpers

/// The explicit `private` on each member is required, not redundant: members of a `private`
/// extension default to `fileprivate`, and a `fileprivate` signature cannot mention `MutableState`,
/// `CachedCredentials` or `LoadOutcome`.
private extension AuthManager {
    /// The one private helper that takes the lock itself — everything below it must be called with
    /// the lock already held, and `SafeMutex` is non-reentrant.
    private func invalidateSession(sessionUID: String, isAuthenticatedSession: Bool) {
        let notification = state.withLock { state -> UncheckedSendable<() -> Void> in
            ensureLoaded(&state)
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            let userId = state.cachedCredentials[key]?.credential.userID
            removeCredentials(for: sessionUID, in: &state)
            persist(&state)
            return sessionInvalidationNotification(state,
                                                   sessionId: sessionUID,
                                                   userId: userId,
                                                   isAuthenticatedSession: isAuthenticatedSession)
        }
        notification.value()
    }

    private func ensureLoaded(_ state: inout MutableState) {
        assertDidSetUp(state)
        // Lazy recovery from a transient read failure (e.g. extension launched before the
        // keychain/symmetric key became available). Always safe to retry: a failure leaves the
        // cache untouched, and a success is merged under any unpersisted mutations by `apply`.
        // Unlike `setUp()` this reads under the lock, but only while recovering — once
        // `storageLoaded` is true this is a boolean check.
        //
        // Silent on failure: the lookups are called once per request, so a failure that lasts
        // (device locked, app locked) would write one error per request into
        // `LogManagerConfig.maxLogLines`. `setUp()` already logs it once per launch and foreground.
        guard state.didSetUp, !state.storageLoaded else { return }
        apply(readFromKeychain(logFailure: false), to: &state)
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
    /// Outcome of reading the stored sessions. Split from `apply` so `setUp()` can do the keychain
    /// syscall, decryption and JSON decoding before it takes the lock.
    private enum LoadOutcome {
        /// Read and decoded. An absent or corrupt blob decodes to an empty set.
        case loaded(CachedCredentials)
        /// Transient failure (keychain unreadable, symmetric key unavailable). The stored blob
        /// is still valid, so the in-memory cache must be left alone and persistence suppressed.
        case unreadable
    }

    /// `logFailure` is `false` for the per-lookup retry in `ensureLoaded`, which would otherwise
    /// report the same failure once per request.
    private func readFromKeychain(logFailure: Bool) -> LoadOutcome {
        let encrypted: Data?
        do {
            encrypted = try keychain.dataOrError(forKey: Self.storageKey)
        } catch {
            // Transient (e.g. data protection / device locked): keep the stored blob,
            // suppress persistence until a successful read.
            if logFailure {
                logger.error("Failed to read stored sessions from keychain, will retry: \(error)")
            }
            return .unreadable
        }

        guard let encrypted else {
            // Nothing stored: first run or post-wipe.
            return .loaded([:])
        }

        do {
            let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
            do {
                let decrypted = try symmetricKey.decrypt(encrypted)
                let decoded = try JSONDecoder().decode(CachedCredentials.self, from: decrypted)
                return .loaded(decoded)
            } catch {
                // Key is available but the payload doesn't decrypt/decode: unrecoverable
                // corruption or a rotated key. Wipe, as the previous implementation did.
                logger.error("Failed to decrypt stored sessions, wiping: \(error)")
                try? keychain.removeOrError(forKey: Self.storageKey)
                return .loaded([:])
            }
        } catch {
            // Symmetric key unavailable (assumed transient, e.g. keymaker not unlocked yet).
            if logFailure {
                logger.error("Symmetric key unavailable, keeping stored sessions: \(error)")
            }
            return .unreadable
        }
    }

    /// Swaps a keychain snapshot into the cache. Callers hold the lock.
    ///
    /// When the cache holds mutations that never reached the keychain it is the fresher copy for
    /// those keys: keep them and *flush* instead of overwriting. Flushing is the whole point —
    /// refusing to reload at all was unrecoverable, because `persist` requires `storageLoaded` and
    /// only a successful read sets it. A mutation during a read failure therefore suppressed
    /// persistence for the rest of the process lifetime, losing every token refreshed afterwards,
    /// which is the stale-refresh-token logout this class exists to prevent.
    private func apply(_ outcome: LoadOutcome, to state: inout MutableState) {
        guard case let .loaded(stored) = outcome else {
            state.storageLoaded = false
            return
        }
        state.storageLoaded = true

        guard !state.hasUnpersistedChanges else {
            // Memory wins for the keys it holds — those mutations never reached the keychain — but
            // keys only the keychain has must survive: another module may have added an account,
            // and a process that started unreadable (app lock: no main key yet, hence no symmetric
            // key) holds nothing but the unauthenticated session obtained meanwhile. Replacing
            // would flush that over every stored session and log all accounts out for good.
            //
            // The cost is the mirror image, and the cheaper one: an entry removed while we could
            // not persist comes back, and the next 401 invalidates it again.
            state.cachedCredentials = stored.merging(state.cachedCredentials) { _, cached in cached }
            persist(&state)
            return
        }

        let previous = state.cachedCredentials
        state.cachedCredentials = stored
        logDroppedSessions(previous: previous, current: stored)
    }

    /// Another module signing out is a legitimate reason for entries to disappear, but it reaches
    /// us as a silent cache shrink rather than a session invalidation. Losing *every* session is
    /// worth an error: the UI stays logged in and the only other symptom is blanket 401s.
    private func logDroppedSessions(previous: CachedCredentials, current: CachedCredentials) {
        let dropped = Set(previous.keys).subtracting(current.keys).count
        guard dropped > 0 else { return }
        if current.isEmpty {
            logger.error("""
            Session reload cleared all \(dropped) stored entries: the shared keychain was wiped \
            or reset by another module. Requests will fail with 401 until the user logs in again.
            """)
        } else {
            logger.warning("Session reload dropped \(dropped) of \(previous.count) stored entries")
        }
    }

    /// Also owns `hasUnpersistedChanges`, so every mutation gets it right by construction
    /// instead of each call site having to remember to flag itself.
    private func persist(_ state: inout MutableState) {
        guard state.storageLoaded else {
            // Never overwrite a keychain blob we could not read: with a failed load the
            // in-memory cache is a strict subset of reality and saving it would log out
            // every stored user.
            logger.error("Skipping session persistence: stored sessions were never loaded")
            state.hasUnpersistedChanges = true
            return
        }
        do {
            let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
            let data = try JSONEncoder().encode(state.cachedCredentials)
            let encryptedContent = try symmetricKey.encrypt(data)
            try keychain.setOrError(encryptedContent, forKey: Self.storageKey)
            state.hasUnpersistedChanges = false
        } catch {
            logger.error("Failed to save user sessions in keychain: \(error)")
            state.hasUnpersistedChanges = true
        }
    }
}

// MARK: - Keychain codable wrappers for credential elements & extensions

public struct Credentials: Hashable, Sendable, Codable {
    public let credential: Credential
    public let authCredential: AuthCredential
    public let module: PassModule
}

private struct CredentialsKey: Hashable, Codable {
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
