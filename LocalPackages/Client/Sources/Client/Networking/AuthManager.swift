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

    func setUpDelegate(_ delegate: any AuthHelperDelegate)
    func getCredential(userId: String) -> AuthCredential?
    func clearSessions(sessionId: String)
    func clearSessions(userId: String)
    func isAuthenticated(userId: String) -> Bool
    func removeCredentials(userId: String)
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
    /// Work-around to keep track of `Credential` mostly for scopes check
    /// as we don't store `Credential` as-is but convert to `AuthCredential` which doesn't contains `scopes`
    /// A dictionary with `sessionUID` as keys
    private var cachedCredentials: [String: AuthElement] = [:]
    private let keychain: any KeychainProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let module: PassModule
    private let serialAccessQueue = DispatchQueue(label: "me.pass.authmanager_queue")
    private let _sessionWasInvalidated: PassthroughSubject<(sessionId: String, userId: String?), Never> = .init()
    private let logger: Logger

    public private(set) weak var delegate: (any AuthHelperDelegate)?
    // swiftlint:disable:next identifier_name
    public weak var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)?

    // This exposes a read only publisher to the rest of the application as AnyPublisher has no send function
    public var sessionWasInvalidated: AnyPublisher<(sessionId: String, userId: String?), Never> {
        _sessionWasInvalidated.eraseToAnyPublisher()
    }

    public static let storageKey = "authManagerStorageKey"

    public init(keychain: any KeychainProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                module: PassModule,
                logManager: any LogManagerProtocol) {
        self.keychain = keychain
        self.symmetricKeyProvider = symmetricKeyProvider
        self.module = module
        logger = .init(manager: logManager)
        cachedCredentials = getLocalSessions()
    }

    public func setUpDelegate(_ delegate: any AuthHelperDelegate) {
        serialAccessQueue.sync {
            self.delegate = delegate
        }
    }

    public func getCredential(userId: String) -> AuthCredential? {
        logger.info("getting authCredential for userId id \(userId)")

        return serialAccessQueue.sync {
            var hasher = Hasher()
            hasher.combine(module)
            hasher.combine(userId)
            guard let cred = cachedCredentials.firstValueForHash(matching: hasher.finalize()) else {
                return nil
            }
            return cred.authCredential
        }
    }

    public func removeCredentials(userId: String) {
        logger.info("Removing credential for userId id \(userId)")

        serialAccessQueue.sync {
            cachedCredentials = cachedCredentials.filter { _, value in
                value.credential.userID != userId
            }
            saveLocalSessions()
        }
    }

    public func credential(sessionUID: String) -> Credential? {
        logger.info("Getting credential for session id \(sessionUID)")

        return serialAccessQueue.sync {
            let key = getCacheKeyFor(sessionId: sessionUID, currentModule: module)

            return cachedCredentials[key]?.credential
        }
    }

    public func authCredential(sessionUID: String) -> AuthCredential? {
        logger.info("Getting authCredential for session id \(sessionUID)")

        return serialAccessQueue.sync {
            let key = getCacheKeyFor(sessionId: sessionUID, currentModule: module)

            guard let cred = cachedCredentials[key]?.authCredential else {
                return nil
            }

            return cred
        }
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
        logger.info("Update Session credentials with session id \(sessionUID)")

        serialAccessQueue.sync {
            for passModule in PassModule.allCases {
                let key = getCacheKeyFor(sessionId: sessionUID, currentModule: passModule)
                let newCredentials = getAuthElement(credential: credential, module: passModule)
                let newAuthCredential = newCredentials.authCredential
                    .updatedKeepingKeyAndPasswordDataIntact(credential: credential)
                cachedCredentials[key] = AuthElement(credential: credential,
                                                     authCredential: newAuthCredential,
                                                     module: passModule)
            }
            saveLocalSessions()
            sendCredentialUpdateInfo(sessionId: sessionUID)
        }
    }

    public func onSessionObtaining(credential: Credential) {
        logger.info("Obtained Session credentials with session id \(credential.UID)")

        serialAccessQueue.sync {
            // The forking of sessions should be done at this point in the future and any looping on Pass module
            // should be removed
            for passModule in PassModule.allCases {
                let key = getCacheKeyFor(sessionId: credential.UID, currentModule: passModule)
                let newCredentials = getAuthElement(credential: credential, module: passModule)
                cachedCredentials[key] = newCredentials
            }
            saveLocalSessions()
            sendCredentialUpdateInfo(sessionId: credential.UID)
        }
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {
        logger.info("Additional credentials for session id \(sessionUID)")

        serialAccessQueue.sync {
            for passModule in PassModule.allCases {
                let key = getCacheKeyFor(sessionId: sessionUID, currentModule: passModule)
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
            saveLocalSessions()
            sendCredentialUpdateInfo(sessionId: sessionUID)
        }
    }

    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
        logger.info("Authenticated session invalidated for session id \(sessionUID)")

        serialAccessQueue.sync {
            let currentSession = cachedCredentials[getCacheKeyFor(sessionId: sessionUID, currentModule: module)]

            for passModule in PassModule.allCases {
                let key = getCacheKeyFor(sessionId: sessionUID, currentModule: passModule)
                cachedCredentials[key] = nil
            }

            saveLocalSessions()
            sendSessionInvalidationInfo(sessionId: sessionUID, isAuthenticatedSession: true)
            _sessionWasInvalidated.send((sessionId: sessionUID, userId: currentSession?.credential.userID))
        }
    }

    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
        logger.info("unauthenticated session invalidated for session id \(sessionUID)")

        serialAccessQueue.sync {
            let currentSession = cachedCredentials[getCacheKeyFor(sessionId: sessionUID, currentModule: module)]

            for passModule in PassModule.allCases {
                let key = getCacheKeyFor(sessionId: sessionUID, currentModule: passModule)
                cachedCredentials[key] = nil
            }
            saveLocalSessions()
            sendSessionInvalidationInfo(sessionId: sessionUID, isAuthenticatedSession: false)
            _sessionWasInvalidated.send((sessionId: sessionUID, userId: currentSession?.credential.userID))
        }
    }

    public func clearSessions(sessionId: String) {
        logger.info("Clear sessions for session id \(sessionId)")

        serialAccessQueue.sync {
            for module in PassModule.allCases {
                let key = getCacheKeyFor(sessionId: sessionId, currentModule: module)
                cachedCredentials[key] = nil
            }
            saveLocalSessions()
        }
    }

    public func clearSessions(userId: String) {
        logger.info("Clear sessions for user id \(userId)")

        serialAccessQueue.sync {
            cachedCredentials = cachedCredentials.filter { $0.value.credential.userID != userId }
            saveLocalSessions()
        }
    }
}

// MARK: - Utils

private extension AuthManager {
    func getAuthElement(credential: Credential,
                        authCredential: AuthCredential? = nil,
                        module: PassModule) -> AuthElement {
        AuthElement(credential: credential,
                    authCredential: authCredential ?? AuthCredential(credential),
                    module: module)
    }

    func sendCredentialUpdateInfo(sessionId: String) {
        let key = getCacheKeyFor(sessionId: sessionId, currentModule: module)
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
    func saveLocalSessions() {
        do {
            let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
            let data = try JSONEncoder().encode(cachedCredentials.toSavedAuthElementDic)
            let encryptedContent = try symmetricKey.encrypt(data.encodeBase64())
            try keychain.setOrError(encryptedContent, forKey: Self.storageKey)
        } catch {
            logger.error("Failed to saved user sessions in keychain: \(error)")
        }
    }

    func getLocalSessions() -> [String: AuthElement] {
        guard let encryptedContent = try? keychain.stringOrError(forKey: Self.storageKey),
              let symmetricKey = try? symmetricKeyProvider.getSymmetricKey() else {
            return [:]
        }

        do {
            let decryptedContent = try symmetricKey.decrypt(encryptedContent)
            guard let decryptedContentData = try decryptedContent.base64Decode() else {
                return [:]
            }
            let content = try JSONDecoder().decode([String: SavedAuthElement].self, from: decryptedContentData)
            return content.toAuthElementDic
        } catch {
            logger.error("Failed to decrypted user sessions from keychain: \(error)")
            try? keychain.removeOrError(forKey: Self.storageKey)
            return [:]
        }
    }

    // This is to differentiate sessions from app and extensions until we have forking in place
    func getCacheKeyFor(sessionId: String, currentModule: PassModule) -> String {
        "\(currentModule.rawValue)\(sessionId)"
    }
}

// MARK: - Keychain codable wrappers for credential elements & extensions

private struct AuthElement: Hashable, Sendable {
    let credential: Credential
    let authCredential: AuthCredential
    let module: PassModule

    public func hash(into hasher: inout Hasher) {
        hasher.combine(module)
        hasher.combine(credential.userID)
    }

    func copy(newAuthCredential: AuthCredential) -> AuthElement {
        AuthElement(credential: credential,
                    authCredential: newAuthCredential,
                    module: module)
    }
}

private struct PassCredential: Equatable, Codable {
    var UID: String
    var accessToken: String
    var refreshToken: String
    var userName: String
    var userID: String
    var scopes: [String]
    var password: String

    init(UID: String,
         accessToken: String,
         refreshToken: String,
         userName: String,
         userID: String,
         scopes: [String],
         password: String = "") {
        self.UID = UID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userName = userName
        self.userID = userID
        self.scopes = scopes
        self.password = password
    }
}

private struct SavedAuthElement: Codable {
    let credential: PassCredential
    let authCredential: AuthCredential
    let module: PassModule
}

private extension [String: AuthElement] {
    func firstValueForHash(matching hash: Int) -> AuthElement? {
        for (_, value) in self where value.hashValue == hash {
            return value
        }
        return nil
    }

    var toSavedAuthElementDic: [String: SavedAuthElement] {
        var saved = [String: SavedAuthElement]()
        for (key, value) in self {
            saved[key] = value.toSavedAuthElement
        }
        return saved
    }
}

private extension [String: SavedAuthElement] {
    var toAuthElementDic: [String: AuthElement] {
        var saved = [String: AuthElement]()
        for (key, value) in self {
            saved[key] = value.toAuthElement
        }
        return saved
    }
}

private extension SavedAuthElement {
    var toAuthElement: AuthElement {
        AuthElement(credential: credential.toCredential,
                    authCredential: authCredential,
                    module: module)
    }
}

private extension AuthElement {
    var toSavedAuthElement: SavedAuthElement {
        SavedAuthElement(credential: credential.toPassCredential,
                         authCredential: authCredential,
                         module: module)
    }
}

private extension Credential {
    var toPassCredential: PassCredential {
        PassCredential(UID: UID,
                       accessToken: accessToken,
                       refreshToken: refreshToken,
                       userName: userName,
                       userID: userID,
                       scopes: scopes,
                       password: mailboxPassword)
    }
}

private extension PassCredential {
    var toCredential: Credential {
        Credential(UID: UID,
                   accessToken: accessToken,
                   refreshToken: refreshToken,
                   userName: userName,
                   userID: userID,
                   scopes: scopes,
                   mailboxPassword: password)
    }
}
