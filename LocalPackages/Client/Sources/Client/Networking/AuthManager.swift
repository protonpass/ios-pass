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
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUtilities

// swiftlint:disable file_length

public protocol AuthManagerProtocol: AuthDelegate {
    func setUpDelegate(_ delegate: any AuthHelperDelegate,
                       callingItOn executor: CompletionBlockExecutor?)

    func addCredential(credential: Credential)
    func getCredential(userId: String) -> AuthCredential?
}

extension UserDefaults {
    // Save Codable object to UserDefaults
    func setCodable(_ value: some Codable, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(value) {
            set(encoded, forKey: key)
        }
    }

    // Retrieve Codable object from UserDefaults
    func codable<T: Codable>(forKey key: String) -> T? {
        if let savedData = data(forKey: key) {
            let decoder = JSONDecoder()
            if let decodedObject = try? decoder.decode(T.self, from: savedData) {
                return decodedObject
            }
        }
        return nil
    }
}

// Save the User object to UserDefaults
// UserDefaults.standard.setCodable(user, forKey: "currentUser")

//// Retrieve the User object from UserDefaults
// if let savedUser: User = UserDefaults.standard.codable(forKey: "currentUser") {
//    print("User name: \(savedUser.name), age: \(savedUser.age)")
// } else {
//    print("No user found in UserDefaults")
// }

// extension AuthCredential {
//    var toCredential: Credential {
//        Credential(self)
//    }
// }

// public convenience init(_ credential: Credential) {
//    self.init(sessionID: credential.UID,
//              accessToken: credential.accessToken,
//              refreshToken: credential.refreshToken,
//              userName: credential.userName,
//              userID: credential.userID,
//              privateKey: nil,
//              passwordKeySalt: nil)
//    update(password: credential.mailboxPassword)
// }

// private struct AuthManagerKey: Hashable, Codable {
//    let sessionId: String
//    let module: PassModule
// }

private struct AuthElement: Hashable {
    let credential: Credential
    let authCredential: AuthCredential
    let module: PassModule

    public func hash(into hasher: inout Hasher) {
        hasher.combine(module)
        hasher.combine(credential.userID)
    }
}

struct PassCredential: Equatable, Codable {
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

// public convenience init(_ credential: Credential) {
//    self.init(sessionID: credential.UID,
//              accessToken: credential.accessToken,
//              refreshToken: credential.refreshToken,
//              userName: credential.userName,
//              userID: credential.userID,
//              privateKey: nil,
//              passwordKeySalt: nil)
//    update(password: credential.mailboxPassword)
// }

public final class AuthManager: AuthManagerProtocol {
//    private let credentialProvider: Atomic<any CredentialProvider>

    public private(set) weak var delegate: (any AuthHelperDelegate)?
    // swiftlint:disable:next identifier_name
    public weak var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)?
    private var delegateExecutor: CompletionBlockExecutor?

    /// Work-around to keep track of `Credential` mostly for scopes check
    /// as we don't store `Credential` as-is but convert to `AuthCredential` which doesn't contains `scopes`
    /// A dictionary with `sessionUID` as keys
    private var cachedCredentials: [String: AuthElement] = [:]

    private let key = "authManagerStorageKey"
    let keychain: any KeychainProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let module: PassModule

    public init(keychain: any KeychainProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                module: PassModule) {
//        self.credentialProvider = .init(credentialProvider)
        self.keychain = keychain
        self.symmetricKeyProvider = symmetricKeyProvider
        self.module = module
        cachedCredentials = getLocalSessions()
    }

    public func setUpDelegate(_ delegate: any AuthHelperDelegate,
                              callingItOn executor: CompletionBlockExecutor? = nil) {
        if let executor {
            delegateExecutor = executor
        } else {
            let dispatchQueue = DispatchQueue(label: "me.proton.core.auth-helper.default", qos: .userInitiated)
            delegateExecutor = .asyncExecutor(dispatchQueue: dispatchQueue)
        }
        self.delegate = delegate
    }

    public func addCredential(credential: Credential) {}

    public func getCredential(userId: String) -> AuthCredential? {
        var hasher = Hasher()
        hasher.combine(module)
        hasher.combine(userId)
        guard let cred = cachedCredentials.firstValueForHash(matching: hasher.finalize()) else {
            return nil
        }
        return cred.authCredential
    }

//    private func getAuthManagerKey(sessionId: String) -> AuthManagerKey {
//        AuthManagerKey(sessionId: sessionId, module: module)
//    }

    public func credential(sessionUID: String) -> Credential? {
        cachedCredentials[sessionUID]?.credential

//        credentialProvider.transform { credentialProvider in
//            if let credential = cachedCredentials[sessionUID] {
//                return credential.toCredential
//            }
//
//            guard let authCredential = credentialProvider.getCredential() else {
//                return nil
//            }
//            guard authCredential.sessionID == sessionUID else {
//                PMLog.error("Asked for wrong credentials. It's a programmers error and should be investigated")
//                return nil
//            }
//            return Credential(authCredential)
//        }
    }

    public func authCredential(sessionUID: String) -> AuthCredential? {
        guard let cred = cachedCredentials[sessionUID]?.authCredential else {
            return nil
        }

        return cred
//        credentialProvider.transform { credentialProvider in
//            guard let authCredential = credentialProvider.getCredential() else {
//                return nil
//            }
//            guard authCredential.sessionID == sessionUID else {
//                PMLog.error("Asked for wrong credentials. It's a programmers error and should be investigated")
//                return nil
//            }
//            return authCredential
//        }
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
        cachedCredentials[sessionUID] = getAuthElement(credential: credential)
        saveLocalSessions()
//        UserDefaults.standard.setCodable(cachedCredentials, forKey: key)
//
//        credentialProvider.mutate { credentialProviderUpdated in
//            defer { cachedCredentials[sessionUID] = credential }
//
//            guard let authCredential = credentialProviderUpdated.getCredential() else {
//                credentialProviderUpdated.setCredential(AuthCredential(credential))
//                return
//            }
//
//            guard authCredential.sessionID == sessionUID else {
//                PMLog
//                    .error("Asked for updating credentials of a wrong session. It should be investigated")
//                return
//            }
//
//            // we don't nil out the key and password to avoid loosing this information unintentionaly
//            let updatedAuth = authCredential.updatedKeepingKeyAndPasswordDataIntact(credential:
//                credential)
//
//            credentialProviderUpdated.setCredential(updatedAuth)
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: updatedAuth,
//                                                credential: credential,
//                                                for: sessionUID)
//            }
//        }
    }

    public func onSessionObtaining(credential: Credential) {
        cachedCredentials[credential.UID] = getAuthElement(credential: credential)
        saveLocalSessions()

//        UserDefaults.standard.setCodable(cachedCredentials, forKey: key)

//        credentialProvider.mutate { credentialProvider in
//            let sessionUID = credential.UID
//
//            defer { cachedCredentials[sessionUID] = credential }
//
//            let newCredentials = AuthCredential(credential)
//
//            credentialProvider.setCredential(newCredentials)
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: newCredentials,
//                                                credential: credential,
//                                                for: sessionUID)
//            }
//        }
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {
//        guard let credential = cachedCredentials[sessionUID]?.auth else {
//            return
//        }
//
//        if let password {
//            authCredential.update(password: password)
//        }
//        let saltToUpdate = salt ?? authCredential.passwordKeySalt
//        let privateKeyToUpdate = privateKey ?? authCredential.privateKey
//
//        authCredential.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
//        cachedCredentials[sessionUID] = getAuthElement(element: authCredential)
//        UserDefaults.standard.setCodable(cachedCredentials, forKey: key)
//        delegate?.credentialsWereUpdated(authCredential: authCredential,
//                                         credential: authCredential.toCredential,
//                                         for: sessionUID)

        guard var element = cachedCredentials[sessionUID] else {
            return
        }

        if let password {
            element.authCredential.update(password: password)
        }
        let saltToUpdate = salt ?? element.authCredential.passwordKeySalt
        let privateKeyToUpdate = privateKey ?? element.authCredential.privateKey
        element.authCredential.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
        cachedCredentials[sessionUID] = element
//                UserDefaults.standard.setCodable(cachedCredentials, forKey: key)
        delegate?.credentialsWereUpdated(authCredential: element.authCredential,
                                         credential: element.credential,
                                         for: sessionUID)

//        credentialProvider.mutate { credentialProvider in
//            guard let authCredential = credentialProvider.getCredential() else {
//                return
//            }
//            guard authCredential.sessionID == sessionUID else {
//                PMLog
//                    .error("Asked for updating credentials of a wrong session. It should be investigated")
//                return
//            }
//
//            if let password {
//                authCredential.update(password: password)
//            }
//            let saltToUpdate = salt ?? authCredential.passwordKeySalt
//            let privateKeyToUpdate = privateKey ?? authCredential.privateKey
//            authCredential.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
//            credentialProvider.setCredential(authCredential)
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: authCredential,
//                                                credential: Credential(authCredential),
//                                                for: sessionUID)
//            }
//        }
    }

    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
        cachedCredentials[sessionUID] = nil
        saveLocalSessions()
        delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)

//        credentialProvider.mutate { credentialProvider in
//            guard let authCredential = credentialProvider.getCredential() else {
//                return
//            }
//            guard authCredential.sessionID == sessionUID else {
//                PMLog
//                    .error("Asked for logout of wrong session. It should be investigated")
//                return
//            }
//            credentialProvider.setCredential(nil)
//
//            delegateExecutor?.execute { [weak self] in
//                guard let self else {
//                    return
//                }
//                delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
//            }
//            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID,
//                                                                                   isAuthenticatedSession: true)
//        }
    }

    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
        cachedCredentials[sessionUID] = nil
        saveLocalSessions()
        delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
//        credentialProvider.mutate { credentialProvider in
//            guard let authCredential = credentialProvider.getCredential() else {
//                return
//            }
//            guard authCredential.sessionID == sessionUID else {
//                PMLog
//                    .error("Asked for erasing the credentials of a wrong session. It should be investigated")
//                return
//            }
//            credentialProvider.setCredential(nil)
//
//            delegateExecutor?.execute { [weak self] in
//                guard let self else {
//                    return
//                }
//                delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
//            }
//            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID,
//                                                                                   isAuthenticatedSession: false)
//        }
    }
}

// MARK: - Utils

import ProtonCoreKeymaker

private extension AuthManager {
    private func getAuthElement(credential: Credential, authCredential: AuthCredential? = nil) -> AuthElement {
        AuthElement(credential: credential,
                    authCredential: authCredential ?? AuthCredential(credential),
                    module: module)
    }
}

// MARK: - Storage

private extension AuthManager {
    func saveLocalSessions() {
        do {
//            let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
//            let codableContent = cachedCredentials.toSavedAuthElementDic
            let data = try JSONEncoder().encode(cachedCredentials.toSavedAuthElementDic)
//            let encryptedContent = try symmetricKey.encrypt(data.encodeBase64())
            try keychain.setOrError(data, forKey: key)
        } catch {
            // TODO: need to log
            print(error)
        }
    }

    func getLocalSessions() -> [String: AuthElement] {
        guard let encryptedContent = try? keychain.dataOrError(forKey: key),
              let symmetricKey = try? symmetricKeyProvider.getSymmetricKey() else {
            return [:]
        }

        do {
//            let decryptedContent = try symmetricKey.decrypt(encryptedContent)
//            guard let decryptedContentData = try decryptedContent.base64Decode() else {
//                return [:]
//            }
            let content = try JSONDecoder().decode([String: SavedAuthElement].self, from: encryptedContent)
            return content.toAuthElementDic
        } catch {
            try? keychain.removeOrError(forKey: key)
            return [:]
        }
    }
}

private struct SavedAuthElement: Codable {
    let credential: PassCredential
    let authCredential: AuthCredential
    let module: PassModule
}

private extension [String: AuthElement] {
    func firstValueForHash(matching hash: Int) -> AuthElement? {
        for (_, value) in self {
            if value.hashValue == hash {
                return value
            }
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

extension SavedAuthElement {
    var toAuthElement: AuthElement {
        AuthElement(credential: credential.toCredential,
                    authCredential: authCredential,
                    module: module)
    }
}

extension AuthElement {
    var toSavedAuthElement: SavedAuthElement {
        SavedAuthElement(credential: credential.toPassCredential,
                         authCredential: authCredential,
                         module: module)
    }
}

extension Credential {
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

extension PassCredential {
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

//
//
// @propertyWrapper
// public struct LockedKeychainStorage<Value: Codable> {
//    private let key: String
//    private let defaultValue: Value
//    private let mainKeyProvider: any MainKeyProvider
//    private let keychain: any KeychainProtocol
//    private let logger: Logger
//
//    public init(key: String,
//                defaultValue: Value,
//                keychain: any KeychainProtocol,
//                mainKeyProvider: any MainKeyProvider,
//                logManager: any LogManagerProtocol) {
//        self.key = key
//        self.defaultValue = defaultValue
//        self.keychain = keychain
//        self.mainKeyProvider = mainKeyProvider
//        logger = .init(manager: logManager)
//    }
//
//    public var wrappedValue: Value {
//        get {
//            do {
//                return try getValue(for: key)
//            } catch {
//                logger.debug("Error retrieving data for key \(key). Fallback to default value.")
//                logger.error(error)
//                return defaultValue
//            }
//        }
//
//        set {
//            do {
//                try setValue(newValue, for: key)
//            } catch {
//                logger.error("Error setting data for key \(key) \(error.localizedDescription)")
//            }
//        }
//    }
// }
//
// private extension LockedKeychainStorage {
//    func getValue(for key: String) throws -> Value {
//        guard let cypherdata = try keychain.dataOrError(forKey: key) else {
//            logger.warning("cypherdata does not exist for key \(key). Fall back to defaultValue.")
//            return defaultValue
//        }
//
//        guard let mainKey = mainKeyProvider.mainKey else {
//            logger.warning("mainKey is null for key \(key). Fall back to defaultValue.")
//            return defaultValue
//        }
//
//        do {
//            let lockedData = Locked<Data>(encryptedValue: cypherdata)
//            let unlockedData = try lockedData.unlock(with: mainKey)
//            return try JSONDecoder().decode(Value.self, from: unlockedData)
//        } catch {
//            // Consider that the cypherdata is lost => remove it
//            logger.error("Corrupted data for key \(key). Fall back to defaultValue.")
//            logger.error(error)
//            try keychain.removeOrError(forKey: key)
//            return defaultValue
//        }
//    }
//
//    func setValue(_ value: Value, for key: String) throws {
//        guard let mainKey = mainKeyProvider.mainKey else {
//            logger.warning("mainKey is null for key \(key). Early exit")
//            return
//        }
//
//        if let optional = value as? (any AnyOptional), optional.isNil {
//            // Set to nil => remove from keychain
//            try keychain.removeOrError(forKey: key)
//        } else {
//            do {
//                let data = try JSONEncoder().encode(value)
//                let lockedData = try Locked<Data>(clearValue: data, with: mainKey)
//                let cypherdata = lockedData.encryptedValue
//                try keychain.setOrError(cypherdata, forKey: key)
//            } catch {
//                logger.error("Failed to serialize data for key \(key) \(error.localizedDescription)")
//            }
//        }
//    }
// }
//
//

//
//
// public protocol AuthHelperDelegate: AuthSessionInvalidatedDelegate {
//    // if credentials are persisted, this is the place to persist new ones
//    func credentialsWereUpdated(authCredential: AuthCredential, credential: Credential, for sessionUID: String)
// }
//
// public final class AuthHelper: AuthDelegate {
//
//    private let currentCredentials: Atomic<(AuthCredential, Credential)?>
//
//    public private(set) weak var delegate: AuthHelperDelegate?
//    public weak var authSessionInvalidatedDelegateForLoginAndSignup: AuthSessionInvalidatedDelegate?
//    private var delegateExecutor: CompletionBlockExecutor?
//
//    public init(authCredential: AuthCredential) {
//        let credential = Credential(authCredential)
//        self.currentCredentials = .init((authCredential, credential))
//    }
//
//    public init(credential: Credential) {
//        let authCredential = AuthCredential(credential)
//        self.currentCredentials = .init((authCredential, credential))
//    }
//
//    public init() {
//        self.currentCredentials = .init(nil)
//    }
//
//    public init?(initialBothCredentials: (AuthCredential, Credential)) {
//        let authCredential = initialBothCredentials.0
//        let credential = initialBothCredentials.1
//        guard authCredential.sessionID == credential.UID,
//              authCredential.accessToken == credential.accessToken,
//              authCredential.refreshToken == credential.refreshToken,
//              authCredential.userID == credential.userID,
//              authCredential.userName == credential.userName else {
//            return nil
//        }
//        self.currentCredentials = .init(initialBothCredentials)
//    }
//
//    public func setUpDelegate(_ delegate: AuthHelperDelegate, callingItOn executor: CompletionBlockExecutor? =
//    nil) {
//        if let executor = executor {
//            self.delegateExecutor = executor
//        } else {
//            let dispatchQueue = DispatchQueue(label: "me.proton.core.auth-helper.default", qos: .userInitiated)
//            self.delegateExecutor = .asyncExecutor(dispatchQueue: dispatchQueue)
//        }
//        self.delegate = delegate
//    }
//
//    public func credential(sessionUID: String) -> Credential? {
//        fetchCredentials(for: sessionUID, path: \.1)
//    }
//
//    public func authCredential(sessionUID: String) -> AuthCredential? {
//        fetchCredentials(for: sessionUID, path: \.0)
//    }
//
//    private func fetchCredentials<T>(for sessionUID: String, path: KeyPath<(AuthCredential, Credential), T>) ->
//    T? {
//        currentCredentials.transform { authCredentials in
//            guard let existingCredentials = authCredentials else { return nil }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for wrong credentials. It's a programmers error and should be investigated",
//                sendToExternal: true)
//                return nil
//            }
//            return existingCredentials[keyPath: path]
//        }
//    }
//
//    public func onUpdate(credential: Credential, sessionUID: String) {
//        currentCredentials.mutate { credentialsToBeUpdated in
//
//            guard let existingCredentials = credentialsToBeUpdated else {
//                credentialsToBeUpdated = (AuthCredential(credential), credential)
//                return
//            }
//
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and
//                should be investigated", sendToExternal: true)
//                return
//            }
//
//            // we don't nil out the key and password to avoid loosing this information unintentionaly
//            let updatedAuth = existingCredentials.0.updatedKeepingKeyAndPasswordDataIntact(credential:
//            credential)
//            var updatedCredentials = credential
//
//            // if there's no update in scopes, assume the same scope as previously
//            if updatedCredentials.scopes.isEmpty {
//                updatedCredentials.scopes = existingCredentials.1.scopes
//            }
//
//            credentialsToBeUpdated = (updatedAuth, updatedCredentials)
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: updatedAuth, credential: updatedCredentials, for: sessionUID)
//            }
//        }
//    }
//
//    public func onSessionObtaining(credential: Credential) {
//        currentCredentials.mutate { authCredentials in
//
//            let sessionUID = credential.UID
//            let newCredentials = (AuthCredential(credential), credential)
//
//            authCredentials = newCredentials
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: newCredentials.0, credential: newCredentials.1, for: sessionUID)
//            }
//        }
//    }
//
//    public func onAdditionalCredentialsInfoObtained(sessionUID: String, password: String?, salt: String?,
//    privateKey: String?) {
//        currentCredentials.mutate { authCredentials in
//            guard authCredentials != nil else { return }
//            guard authCredentials?.0.sessionID == sessionUID else {
//                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and
//                should be investigated", sendToExternal: true)
//                return
//            }
//
//            if let password = password {
//                authCredentials?.0.update(password: password)
//            }
//            let saltToUpdate = salt ?? authCredentials?.0.passwordKeySalt
//            let privateKeyToUpdate = privateKey ?? authCredentials?.0.privateKey
//            authCredentials?.0.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
//
//            guard let delegate, let delegateExecutor, let existingCredentials = authCredentials else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: existingCredentials.0, credential: existingCredentials.1, for: sessionUID)
//            }
//        }
//    }
//
//    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
//        currentCredentials.mutate { authCredentials in
//            guard let existingCredentials = authCredentials else { return }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for logout of wrong session. It's a programmers error and should be
//                investigated", sendToExternal: true)
//                return
//            }
//            authCredentials = nil
//
//            delegateExecutor?.execute { [weak self] in
//                self?.delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
//            }
//            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
//        }
//    }
//
//    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
//        currentCredentials.mutate { authCredentials in
//            guard let existingCredentials = authCredentials else { return }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for erasing the credentials of a wrong session. It's a programmers error and
//                should be investigated", sendToExternal: true)
//                return
//            }
//            authCredentials = nil
//
//            delegateExecutor?.execute { [weak self] in
//                self?.delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
//            }
//            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
//        }
//    }
// }
//
//
// public final class AuthHelper: AuthDelegate {
//
//    private let currentCredentials: Atomic<(AuthCredential, Credential)?>
//
//    public private(set) weak var delegate: AuthHelperDelegate?
//    public weak var authSessionInvalidatedDelegateForLoginAndSignup: AuthSessionInvalidatedDelegate?
//    private var delegateExecutor: CompletionBlockExecutor?
//
//    public init(authCredential: AuthCredential) {
//        let credential = Credential(authCredential)
//        self.currentCredentials = .init((authCredential, credential))
//    }
//
//    public init(credential: Credential) {
//        let authCredential = AuthCredential(credential)
//        self.currentCredentials = .init((authCredential, credential))
//    }
//
//    public init() {
//        self.currentCredentials = .init(nil)
//    }
//
//    public init?(initialBothCredentials: (AuthCredential, Credential)) {
//        let authCredential = initialBothCredentials.0
//        let credential = initialBothCredentials.1
//        guard authCredential.sessionID == credential.UID,
//              authCredential.accessToken == credential.accessToken,
//              authCredential.refreshToken == credential.refreshToken,
//              authCredential.userID == credential.userID,
//              authCredential.userName == credential.userName else {
//            return nil
//        }
//        self.currentCredentials = .init(initialBothCredentials)
//    }
//
//    public func setUpDelegate(_ delegate: AuthHelperDelegate, callingItOn executor: CompletionBlockExecutor? =
//    nil) {
//        if let executor = executor {
//            self.delegateExecutor = executor
//        } else {
//            let dispatchQueue = DispatchQueue(label: "me.proton.core.auth-helper.default", qos: .userInitiated)
//            self.delegateExecutor = .asyncExecutor(dispatchQueue: dispatchQueue)
//        }
//        self.delegate = delegate
//    }
//
//    public func credential(sessionUID: String) -> Credential? {
//        fetchCredentials(for: sessionUID, path: \.1)
//    }
//
//    public func authCredential(sessionUID: String) -> AuthCredential? {
//        fetchCredentials(for: sessionUID, path: \.0)
//    }
//
//    private func fetchCredentials<T>(for sessionUID: String, path: KeyPath<(AuthCredential, Credential), T>) ->
//    T? {
//        currentCredentials.transform { authCredentials in
//            guard let existingCredentials = authCredentials else { return nil }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for wrong credentials. It's a programmers error and should be investigated",
//                sendToExternal: true)
//                return nil
//            }
//            return existingCredentials[keyPath: path]
//        }
//    }
//
//    public func onUpdate(credential: Credential, sessionUID: String) {
//        currentCredentials.mutate { credentialsToBeUpdated in
//
//            guard let existingCredentials = credentialsToBeUpdated else {
//                credentialsToBeUpdated = (AuthCredential(credential), credential)
//                return
//            }
//
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and
//                should be investigated", sendToExternal: true)
//                return
//            }
//
//            // we don't nil out the key and password to avoid loosing this information unintentionaly
//            let updatedAuth = existingCredentials.0.updatedKeepingKeyAndPasswordDataIntact(credential:
//            credential)
//            var updatedCredentials = credential
//
//            // if there's no update in scopes, assume the same scope as previously
//            if updatedCredentials.scopes.isEmpty {
//                updatedCredentials.scopes = existingCredentials.1.scopes
//            }
//
//            credentialsToBeUpdated = (updatedAuth, updatedCredentials)
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: updatedAuth, credential: updatedCredentials, for: sessionUID)
//            }
//        }
//    }
//
//    public func onSessionObtaining(credential: Credential) {
//        currentCredentials.mutate { authCredentials in
//
//            let sessionUID = credential.UID
//            let newCredentials = (AuthCredential(credential), credential)
//
//            authCredentials = newCredentials
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: newCredentials.0, credential: newCredentials.1, for: sessionUID)
//            }
//        }
//    }
//
//    public func onAdditionalCredentialsInfoObtained(sessionUID: String, password: String?, salt: String?,
//    privateKey: String?) {
//        currentCredentials.mutate { authCredentials in
//            guard authCredentials != nil else { return }
//            guard authCredentials?.0.sessionID == sessionUID else {
//                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and
//                should be investigated", sendToExternal: true)
//                return
//            }
//
//            if let password = password {
//                authCredentials?.0.update(password: password)
//            }
//            let saltToUpdate = salt ?? authCredentials?.0.passwordKeySalt
//            let privateKeyToUpdate = privateKey ?? authCredentials?.0.privateKey
//            authCredentials?.0.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
//
//            guard let delegate, let delegateExecutor, let existingCredentials = authCredentials else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: existingCredentials.0, credential: existingCredentials.1, for: sessionUID)
//            }
//        }
//    }
//
//    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
//        currentCredentials.mutate { authCredentials in
//            guard let existingCredentials = authCredentials else { return }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for logout of wrong session. It's a programmers error and should be
//                investigated", sendToExternal: true)
//                return
//            }
//            authCredentials = nil
//
//            delegateExecutor?.execute { [weak self] in
//                self?.delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
//            }
//            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
//        }
//    }
//
//    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
//        currentCredentials.mutate { authCredentials in
//            guard let existingCredentials = authCredentials else { return }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for erasing the credentials of a wrong session. It's a programmers error and
//                should be investigated", sendToExternal: true)
//                return
//            }
//            authCredentials = nil
//
//            delegateExecutor?.execute { [weak self] in
//                self?.delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
//            }
//            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
//        }
//    }
// }

//
////
////  FeatureFlagsRepository.swift
////  ProtonCore-FeatureFlags - Created on 29.09.23.
////
////  Copyright (c) 2023 Proton Technologies AG
////
////  This file is part of Proton Technologies AG and ProtonCore.
////
////  ProtonCore is free software: you can redistribute it and/or modify
////  it under the terms of the GNU General Public License as published by
////  the Free Software Foundation, either version 3 of the License, or
////  (at your option) any later version.
////
////  ProtonCore is distributed in the hope that it will be useful,
////  but WITHOUT ANY WARRANTY; without even the implied warranty of
////  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
////  GNU General Public License for more details.
////
////  You should have received a copy of the GNU General Public License
////  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
////
//
// import ProtonCoreLog
// import ProtonCoreServices
// @preconcurrency import ProtonCoreUtilities
// import Foundation
//
/// **
// The FeatureFlagsRepository class is responsible for managing feature flags and their state.
// It conforms to the FeatureFlagsRepositoryProtocol.
// */
// public final class FeatureFlagsRepository: @unchecked Sendable, FeatureFlagsRepositoryProtocol {
//    /// The local data source for feature flags.
//    private var _localDataSource: Atomic<any LocalFeatureFlagsDataSourceProtocol>
//    /// The remote data source for feature flags.
//    private var _remoteDataSource: Atomic<(any RemoteFeatureFlagsDataSourceProtocol)?>
//    private let queue = DispatchQueue(label: "ch.proton.featureflagsrepository_queue", attributes: .concurrent)
//
//    /// The local data source for feature flags.
//    var localDataSource: Atomic<any LocalFeatureFlagsDataSourceProtocol> {
//        get {
//            return queue.sync {
//                _localDataSource
//            }
//        }
//        set {
//            queue.async(flags: .barrier) {
//                self._localDataSource = newValue
//            }
//        }
//    }
//
//    /// The remote data source for feature flags.
//    var remoteDataSource: Atomic<(any RemoteFeatureFlagsDataSourceProtocol)?> {
//        get {
//            return queue.sync {
//                _remoteDataSource
//            }
//        }
//        set {
//            queue.async(flags: .barrier) {
//                self._remoteDataSource = newValue
//            }
//        }
//    }
//
//    /// The configuration for feature flags.
//    private(set) var userId: String {
//        get {
//            return _userId ?? ""
//        }
//        set {
//            _userId = newValue
//            localDataSource.value.setUserIdForActiveSession(newValue)
//        }
//    }
//
//    private var _userId: String?
//
//    public static let shared: FeatureFlagsRepository = .init(
//        localDataSource: Atomic<any LocalFeatureFlagsDataSourceProtocol>(DefaultLocalFeatureFlagsDatasource()),
//        remoteDataSource: Atomic<(any RemoteFeatureFlagsDataSourceProtocol)?>(nil)
//    )
//
//    /**
//     Private initialization of the shared FeatureFlagsRepository instance.
//
//     - Parameters:
//       - localDataSource: The local data source for feature flags.
//       - remoteDataSource: The remote data source for feature flags.
//     */
//    init(localDataSource: Atomic<any LocalFeatureFlagsDataSourceProtocol>,
//         remoteDataSource: Atomic<(any RemoteFeatureFlagsDataSourceProtocol)?>) {
//        self._localDataSource = localDataSource
//        self._remoteDataSource = remoteDataSource
//        self._userId = localDataSource.value.userIdForActiveSession
//    }
//
//    // Internal func for testing
//    func updateRemoteDataSource(with remoteDataSource: Atomic<(any RemoteFeatureFlagsDataSourceProtocol)?>) {
//        self.remoteDataSource = remoteDataSource
//    }
// }
//
//// MARK: - For single-user clients
//
// public extension FeatureFlagsRepository {
//
//    /**
//     Updates the local data source conforming to the `LocalFeatureFlagsProtocol` protocol
//     */
//    func updateLocalDataSource(_ localDataSource: Atomic<any LocalFeatureFlagsDataSourceProtocol>) {
//        self.localDataSource = localDataSource
//    }
//
//    /**
//     Sets the FeatureFlagsRepository configuration with the given user id.
//
//     - Parameters:
//       - userId: The user id used to initialize the configuration for feature flags.
//     */
//    func setUserId(_ userId: String) {
//        self.userId = userId
//    }
//
//    /**
//     Sets the FeatureFlagsRepository remote data source with the given api service.
//
//     - Parameters:
//       - apiService: The api service used to initialize the remote data source for feature flags.
//     */
//    func setApiService(_ apiService: any APIService) {
//       remoteDataSource = Atomic<(any
//       RemoteFeatureFlagsDataSourceProtocol)?>(DefaultRemoteFeatureFlagsDataSource(apiService: apiService))
//    }
//
//    /**
//     Asynchronously fetches the feature flags from the remote data source and updates the local data source.
//
//     - Throws: An error if the operation fails.
//     */
//    func fetchFlags() async throws {
//        guard let remoteDataSource = self.remoteDataSource.value else {
//            assertionFailure("No apiService was set. You need to set the apiService of by calling `setApiService`
//            in order to fetch the feature flags.")
//            return
//        }
//
//        let (flags, userID) = try await remoteDataSource.getFlags()
//        localDataSource.value.upsertFlags(.init(flags: flags), userId: userID)
//    }
//
//    /**
//     A Boolean function indicating if a feature flag is enabled or not.
//     The flag is fetched from the local data source and is intended for use in a single-user context.
//
//     - Parameters:
//       - flag: The flag we want to know the state of.
//       - reloadValue: Pass `true` if you want the latest stored value for the flag. Pass `false` if  you want the
//       "static" value, which is always the same as the first returned.
//     */
//    func isEnabled(_ flag: any FeatureFlagTypeProtocol, reloadValue: Bool) -> Bool {
//        let flags = localDataSource.value.getFeatureFlags(
//            userId: self.userId,
//            reloadFromLocalDataSource: reloadValue
//        )
//        return flags?.getFlag(for: flag)?.enabled ?? false
//    }
//
//    /**
//     A Boolean function indicating if a feature flag is enabled or not.
//     The flag is fetched from the local data source and is intended for use in multi-user contexts.
//
//     - Parameters:
//       - flag: The flag we want to know the state of.
//       - userId: The user id for which we want to check the flag value. If the userId is `nil`, the first-set
//       userId will be used.  See ``setUserId(_)``.
//       - reloadValue: Pass `true` if you want the latest stored value for the flag. Pass `false` if  you want the
//       "static" value, which is always the same as the first returned.
//     */
//    func isEnabled(_ flag: any FeatureFlagTypeProtocol, for userId: String?, reloadValue: Bool) -> Bool {
//        let flags: FeatureFlags?
//
//        if let userId {
//            flags = localDataSource.value.getFeatureFlags(
//                userId: userId,
//                reloadFromLocalDataSource: reloadValue
//            )
//        } else {
//            flags = localDataSource.value.getFeatureFlags(
//                userId: self.userId,
//                reloadFromLocalDataSource: reloadValue
//            )
//        }
//
//        return flags?.getFlag(for: flag)?.enabled ?? false
//    }
// }
//
//// MARK: - Reset
//
// public extension FeatureFlagsRepository {
//    /**
//     Resets all feature flags.
//     */
//    func resetFlags() {
//        localDataSource.value.cleanAllFlags()
//    }
//
//    /**
//     Resets feature flags for a specific user.
//
//     - Parameters:
//        - userId: The ID of the user whose feature flags need to be reset.
//     */
//    func resetFlags(for userId: String) {
//        localDataSource.value.cleanFlags(for: userId)
//    }
//
//    /**
//     Resets userId.
//     */
//    func clearUserId() {
//        localDataSource.value.clearUserId()
//        _userId = ""
//    }
// }

// swiftlint:enable file_length
