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
    func setUpDelegate(_ delegate: any AuthHelperDelegate)

    func getCredential(userId: String) -> AuthCredential?
    func clearSessions(sessionId: String)
    func clearSessions(userId: String)
}

public extension AuthManagerProtocol {
    func isAuthenticated(userId: String) -> Bool {
        guard let credential = getCredential(userId: userId) else {
            return false
        }
        return !credential.isForUnauthenticatedSession
    }
}

public final class AuthManager: AuthManagerProtocol {
    public private(set) weak var delegate: (any AuthHelperDelegate)?
    // swiftlint:disable:next identifier_name
    public weak var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)?
    public static let storageKey = "AuthManagerStorageKey"
    private let serialAccessQueue = DispatchQueue(label: "me.proton.pass.authmanager")

    private typealias CachedCredentials = [CredentialsKey: Credentials]

    private var cachedCredentials: CachedCredentials = [:]
    private let keychain: any KeychainProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let module: PassModule

    public init(keychain: any KeychainProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                module: PassModule) {
        self.keychain = keychain
        self.symmetricKeyProvider = symmetricKeyProvider
        self.module = module
        cachedCredentials = getCachedCredentials()
    }

    public func setUpDelegate(_ delegate: any AuthHelperDelegate) {
        self.delegate = delegate
    }

    public func getCredential(userId: String) -> AuthCredential? {
        serialAccessQueue.sync {
            cachedCredentials
                .first(where: { $0.key.module == module && $0.value.authCredential.userID == userId })?
                .value.authCredential
        }
    }

    public func credential(sessionUID: String) -> Credential? {
        serialAccessQueue.sync {
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            return cachedCredentials[key]?.credential
        }
    }

    public func authCredential(sessionUID: String) -> AuthCredential? {
        serialAccessQueue.sync {
            let key = CredentialsKey(sessionId: sessionUID, module: module)
            return cachedCredentials[key]?.authCredential
        }
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
        serialAccessQueue.sync {
            for passModule in PassModule.allCases {
                let key = CredentialsKey(sessionId: sessionUID, module: passModule)
                let newCredentials = getCredentials(credential: credential, module: passModule)
                let newAuthCredential = newCredentials.authCredential
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
        serialAccessQueue.sync {
            // The forking of sessions should be done at this point in the future and any looping on Pass module
            // should be removed
            for passModule in PassModule.allCases {
                let key = CredentialsKey(sessionId: credential.UID, module: passModule)
                let newCredentials = getCredentials(credential: credential, module: passModule)
                cachedCredentials[key] = newCredentials
            }
            saveCachedCredentialsToKeychain()
            sendCredentialUpdateInfo(sessionId: credential.UID)
        }
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {
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
        serialAccessQueue.sync {
            removeCredentials(for: sessionUID)
            saveCachedCredentialsToKeychain()
            sendSessionInvalidationInfo(sessionId: sessionUID, isAuthenticatedSession: true)
        }
    }

    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
        serialAccessQueue.sync {
            removeCredentials(for: sessionUID)
            saveCachedCredentialsToKeychain()
            sendSessionInvalidationInfo(sessionId: sessionUID, isAuthenticatedSession: false)
        }
    }

    public func clearSessions(sessionId: String) {
        serialAccessQueue.sync {
            removeCredentials(for: sessionId)
            saveCachedCredentialsToKeychain()
        }
    }

    public func clearSessions(userId: String) {
        serialAccessQueue.sync {
            cachedCredentials = cachedCredentials.filter { $0.value.credential.userID != userId }
            saveCachedCredentialsToKeychain()
        }
    }
}

// MARK: - Utils

private extension AuthManager {
    func getCredentials(credential: Credential,
                        authCredential: AuthCredential? = nil,
                        module: PassModule) -> Credentials {
        Credentials(credential: credential,
                    authCredential: authCredential ?? AuthCredential(credential),
                    module: module)
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
            // swiftlint:disable:next todo
            // TODO: need to log
            print(error)
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

private struct Credentials: Hashable, Sendable, Codable {
    let credential: Credential
    let authCredential: AuthCredential
    let module: PassModule
}

private struct CredentialsKey: Hashable, Codable {
    let sessionId: String
    let module: PassModule
}

extension Credential: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case UID
        case accessToken
        case refreshToken
        case userName
        case userID
        case scopes
        case mailboxPassword
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(UID)
        hasher.combine(accessToken)
        hasher.combine(refreshToken)
        hasher.combine(userName)
        hasher.combine(userID)
        hasher.combine(scopes)
        hasher.combine(mailboxPassword)
    }

    public init(from decoder: any Decoder) throws {
        self.init(UID: "",
                  accessToken: "",
                  refreshToken: "",
                  userName: "",
                  userID: "",
                  scopes: [],
                  mailboxPassword: "")
        let values = try decoder.container(keyedBy: CodingKeys.self)
        UID = try values.decode(String.self, forKey: .UID)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        refreshToken = try values.decode(String.self, forKey: .refreshToken)
        userName = try values.decode(String.self, forKey: .userName)
        userID = try values.decode(String.self, forKey: .userID)
        scopes = try values.decode([String].self, forKey: .scopes)
        mailboxPassword = try values.decode(String.self, forKey: .mailboxPassword)
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
    }
}
