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

public final class AuthManager: @unchecked Sendable, AuthManagerProtocol {
    public private(set) weak var delegate: (any AuthHelperDelegate)?
    // swiftlint:disable:next identifier_name
    public weak var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)?
    public static let storageKey = "AuthManagerStorageKey"
    private let serialAccessQueue = DispatchQueue(label: "me.proton.pass.authmanager")

    private typealias CachedCredentials = [CredentialsKey: Credentials]

    private var cachedCredentials: CachedCredentials = [:]
    private let keychain: any KeychainProtocol
    private let symmetricKeyProvider: any NonAsyncSymmetricKeyProvider
    private let module: PassModule
    private let _sessionWasInvalidated: PassthroughSubject<(sessionId: String, userId: String?), Never> = .init()
    private let logger: Logger
    private var didSetUp = false

    // This exposes a read only publisher to the rest of the application as AnyPublisher has no send function
    public var sessionWasInvalidated: AnyPublisher<(sessionId: String, userId: String?), Never> {
        _sessionWasInvalidated.eraseToAnyPublisher()
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
        cachedCredentials = getCachedCredentials()
        didSetUp = true
    }

    public func setUpDelegate(_ delegate: any AuthHelperDelegate) {
        assertDidSetUp()
        serialAccessQueue.sync {
            self.delegate = delegate
        }
    }

    public func getCredential(userId: String) -> AuthCredential? {
        logger.info("getting authCredential for userId id \(userId)")
        assertDidSetUp()

        return serialAccessQueue.sync {
            cachedCredentials
                .first(where: { $0.key.module == module && $0.value.authCredential.userID == userId })?
                .value.authCredential
        }
    }

    public func removeCredentials(userId: String) {
        logger.info("Removing credential for userId id \(userId)")
        assertDidSetUp()

        serialAccessQueue.sync {
            cachedCredentials = cachedCredentials.filter { _, value in
                value.credential.userID != userId
            }
            saveCachedCredentialsToKeychain()
        }
    }

    public func removeAllCredentials() {
        assertDidSetUp()
        serialAccessQueue.sync {
            cachedCredentials = [:]
            saveCachedCredentialsToKeychain()
        }
    }

    public func credential(sessionUID: String) -> Credential? {
        logger.info("Getting credential for session id \(sessionUID)")
        assertDidSetUp()

        return serialAccessQueue.sync {
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            return cachedCredentials[key]?.credential
        }
    }

    public func authCredential(sessionUID: String) -> AuthCredential? {
        logger.info("Getting authCredential for session id \(sessionUID)")
        assertDidSetUp()

        return serialAccessQueue.sync {
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            return cachedCredentials[key]?.authCredential
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
        logger.info("Update Session credentials with session id \(sessionUID)")
        assertDidSetUp()

        serialAccessQueue.sync {
            for passModule in PassModule.allCases {
                let key = CredentialsKey(sessionId: sessionUID, module: passModule)

                let credentials: Credentials = if let cred = cachedCredentials[key] {
                    cred
                } else {
                    // Note: Credential has `mailboxpassword == ""` so the authCredential will have an empty
                    // mailboxpassword
                    // That is why we try to get the cached credentials.
                    Credentials(credential: credential,
                                authCredential: AuthCredential(credential),
                                module: passModule)
                }

                // Note: updatedKeepingKeyAndPasswordDataIntact is necessary because Credential has
                // `mailboxpassword == ""` which would override the mailboxpassword with an empty string.
                let newAuthCredential = credentials.authCredential
                    .updatedKeepingKeyAndPasswordDataIntact(credential: credential)
                cachedCredentials[key] = Credentials(credential: credential,
                                                     authCredential: newAuthCredential,
                                                     module: passModule)
            }
            saveCachedCredentialsToKeychain()
            sendCredentialUpdateInfo(sessionId: sessionUID)
        }
    }

    public func onSessionObtaining(credential: Credential) {
        logger.info("Obtained Session credentials with session id \(credential.UID)")
        assertDidSetUp()

        serialAccessQueue.sync {
            // The forking of sessions should be done at this point in the future and any looping on Pass module
            // should be removed

            // Remove all existing credentials related to the same userID
            // This is to handle logging into the same account multiple times
            for (key, value) in cachedCredentials
                where value.credential.userID == credential.userID {
                cachedCredentials.removeValue(forKey: key)
            }

            for passModule in PassModule.allCases {
                let key = CredentialsKey(sessionId: credential.UID, module: passModule)
                cachedCredentials[key] = Credentials(credential: credential,
                                                     authCredential: AuthCredential(credential),
                                                     module: passModule)
            }
            saveCachedCredentialsToKeychain()
            sendCredentialUpdateInfo(sessionId: credential.UID)
        }
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {
        logger.info("Additional credentials for session id \(sessionUID)")
        assertDidSetUp()

        serialAccessQueue.sync {
            for passModule in PassModule.allCases {
                let key = CredentialsKey(sessionId: sessionUID, module: passModule)
                guard let element = cachedCredentials[key] else {
                    return
                }

                if let password {
                    element.authCredential.update(password: password)
                }
                let saltToUpdate = salt ?? element.authCredential.passwordKeySalt
                let privateKeyToUpdate = privateKey ?? element.authCredential.privateKey
                element.authCredential.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
                cachedCredentials[key] = element
            }
            saveCachedCredentialsToKeychain()
            sendCredentialUpdateInfo(sessionId: sessionUID)
        }
    }

    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
        logger.info("Authenticated session invalidated for session id \(sessionUID)")
        assertDidSetUp()

        serialAccessQueue.sync {
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            let currentSession = cachedCredentials[key]
            removeCredentials(for: sessionUID)
            saveCachedCredentialsToKeychain()
            sendSessionInvalidationInfo(sessionId: sessionUID, isAuthenticatedSession: true)
            _sessionWasInvalidated.send((sessionId: sessionUID, userId: currentSession?.credential.userID))
        }
    }

    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
        logger.info("unauthenticated session invalidated for session id \(sessionUID)")
        assertDidSetUp()

        serialAccessQueue.sync {
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            let currentSession = cachedCredentials[key]
            removeCredentials(for: sessionUID)
            saveCachedCredentialsToKeychain()
            sendSessionInvalidationInfo(sessionId: sessionUID, isAuthenticatedSession: false)
            _sessionWasInvalidated.send((sessionId: sessionUID, userId: currentSession?.credential.userID))
        }
    }

    public func clearSessions(sessionId: String) {
        logger.info("Clear sessions for session id \(sessionId)")
        assertDidSetUp()

        serialAccessQueue.sync {
            removeCredentials(for: sessionId)
            saveCachedCredentialsToKeychain()
        }
    }

    public func clearSessions(userId: String) {
        logger.info("Clear sessions for user id \(userId)")
        assertDidSetUp()

        serialAccessQueue.sync {
            cachedCredentials = cachedCredentials.filter { $0.value.credential.userID != userId }
            saveCachedCredentialsToKeychain()
        }
    }

    public func getAllCurrentCredentials() -> [Credential] {
        assertDidSetUp()
        return cachedCredentials.compactMap { key, element -> Credential? in
            guard key.module == module else {
                return nil
            }
            return element.credential
        }
    }
}

public extension AuthManager {
    /// Introduced on July 2024 for multi accounts support. Can be removed later on.
    func migrate(_ credential: AuthCredential) {
        assertDidSetUp()
        serialAccessQueue.sync {
            for module in PassModule.allCases {
                let key = CredentialsKey(sessionId: credential.sessionID, module: module)
                cachedCredentials[key] = .init(credential: .init(credential),
                                               authCredential: credential,
                                               module: module)
            }
            saveCachedCredentialsToKeychain()
        }
    }

    /// Introduced on February 2025 for CSV import support. Can be removed later on.
    func initializeCredentialsForActionExtension() {
        assertDidSetUp()
        serialAccessQueue.sync {
            if let appCredential = cachedCredentials.first(where: { $0.key.module == .hostApp }) {
                let key = CredentialsKey(sessionId: appCredential.value.authCredential.sessionID,
                                         module: .actionExtension)
                cachedCredentials[key] = appCredential.value
            }
            saveCachedCredentialsToKeychain()
        }
    }

    @_spi(QA)
    func getAllCredentialsOfAllModules() -> [Credentials] {
        assertDidSetUp()
        return Array(cachedCredentials.values)
    }
}

// MARK: - Utils

private extension AuthManager {
    func assertDidSetUp() {
        assert(didSetUp, "AuthManager not set up. Call setUp() function as soon as possible.")
        if !didSetUp {
            logger.error("AuthManager not set up")
        }
    }

    func sendCredentialUpdateInfo(sessionId: String) {
        let key = CredentialsKey(sessionId: sessionId, module: module)
        guard let credentials = cachedCredentials[key] else {
            return
        }

        delegate?.credentialsWereUpdated(authCredential: credentials.authCredential,
                                         credential: credentials.credential,
                                         for: sessionId)
    }

    func sendSessionInvalidationInfo(sessionId: String, isAuthenticatedSession: Bool) {
        delegate?.sessionWasInvalidated(for: sessionId,
                                        isAuthenticatedSession: isAuthenticatedSession)
        authSessionInvalidatedDelegateForLoginAndSignup?
            .sessionWasInvalidated(for: sessionId,
                                   isAuthenticatedSession: isAuthenticatedSession)
    }
}

// MARK: - Storage

private extension AuthManager {
    func saveCachedCredentialsToKeychain() {
        do {
            let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
            let data = try JSONEncoder().encode(cachedCredentials)
            let encryptedContent = try symmetricKey.encrypt(data)
            try keychain.setOrError(encryptedContent, forKey: Self.storageKey)
        } catch {
            logger.error("Failed to saved user sessions in keychain: \(error)")
        }
    }

    func getCachedCredentials() -> [CredentialsKey: Credentials] {
        guard let encryptedContent = try? keychain.dataOrError(forKey: Self.storageKey),
              let symmetricKey = try? symmetricKeyProvider.getSymmetricKey() else {
            return [:]
        }

        do {
            let decryptedContent = try symmetricKey.decrypt(encryptedContent)
            return try JSONDecoder().decode(CachedCredentials.self, from: decryptedContent)
        } catch {
            logger.error("Failed to decrypted user sessions from keychain: \(error)")
            try? keychain.removeOrError(forKey: Self.storageKey)
            return [:]
        }
    }

    func removeCredentials(for sessionUID: String) {
        for module in PassModule.allCases {
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            cachedCredentials[key] = nil
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

extension Credential: Codable, @retroactive Hashable {
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
