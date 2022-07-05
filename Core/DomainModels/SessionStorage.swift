//
// SessionStorage.swift
// Proton Key - Created on 04/07/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Key.
//
// Proton Key is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Key is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Key. If not, see https://www.gnu.org/licenses/.

import ProtonCore_DataModel
import ProtonCore_Keymaker
import ProtonCore_Login

public protocol SessionStorageProvider: AnyObject {
    var credential: PKCredential? { get }
    var salts: [KeySalt]? { get }
    var passphrases: [String: String]? { get }
    var addresses: [Address]? { get }
    var user: User? { get }

    func setCredential(_ credential: PKCredential)
    func setSalts(_ salts: [KeySalt])
    func setPassphrases(_ passphrases: [String: String])
    func setAddresses(_ addresses: [Address])
    func setUser(_ user: User)
    func isSignedIn() -> Bool
    func signOut()
}

/// Dummy SessionStorageProvider serves for preview purposes
public final class PreviewSessionStorage: SessionStorageProvider {
    public var credential: PKCredential?
    public var salts: [KeySalt]?
    public var passphrases: [String: String]?
    public var addresses: [Address]?
    public var user: User?

    public func setCredential(_ credential: PKCredential) {}
    public func setSalts(_ salts: [KeySalt]) {}
    public func setPassphrases(_ passphrases: [String: String]) {}
    public func setAddresses(_ addresses: [Address]) {}
    public func setUser(_ user: User) {}
    public func isSignedIn() -> Bool { false }
    public func signOut() {}
}

public extension SessionStorageProvider where Self == PreviewSessionStorage {
    static var preview: SessionStorageProvider { PreviewSessionStorage() }
}

public final class SessionStorage: SessionStorageProvider {
    private let mainKeyProvider: MainKeyProvider

    public init(mainKeyProvider: MainKeyProvider, keychain: Keychain) {
        self.mainKeyProvider = mainKeyProvider
        self._credential.setKeychain(keychain)
        self._credential.setMainKeyProvider(mainKeyProvider)
        self._salts.setKeychain(keychain)
        self._salts.setMainKeyProvider(mainKeyProvider)
        self._passphrases.setKeychain(keychain)
        self._passphrases.setMainKeyProvider(mainKeyProvider)
        self._addresses.setKeychain(keychain)
        self._addresses.setMainKeyProvider(mainKeyProvider)
        self._user.setKeychain(keychain)
        self._user.setMainKeyProvider(mainKeyProvider)
    }

    // swiftlint:disable let_var_whitespace
    // MARK: - SessionStorageProvider
    @KeychainStorage(key: "credential")
    public private(set) var credential: PKCredential?

    @KeychainStorage(key: "salts")
    public private(set) var salts: [KeySalt]?

    @KeychainStorage(key: "passphrases")
    public private(set) var passphrases: [String: String]?

    @KeychainStorage(key: "addresses")
    public private(set) var addresses: [Address]?

    @KeychainStorage(key: "user")
    public private(set) var user: User?
    // swiftlint:enable let_var_whitespace

    public func setCredential(_ credential: PKCredential) {
        self.credential = credential
    }

    public func setSalts(_ salts: [KeySalt]) {
        self.salts = salts
    }

    public func setPassphrases(_ passphrases: [String: String]) {
        self.passphrases = passphrases
    }

    public func setAddresses(_ addresses: [Address]) {
        self.addresses = addresses
    }

    public func setUser(_ user: User) {
        self.user = user
    }

    public func bind(userData: UserData) {
        self.credential = .init(authCredential: userData.credential, scopes: userData.scopes)
        self.salts = userData.salts
        self.addresses = userData.addresses
        self.passphrases = userData.passphrases
        self.user = userData.user
    }

    public func isSignedIn() -> Bool {
        _credential.hasCypherdata() &&
        _salts.hasCypherdata() &&
        _passphrases.hasCypherdata() &&
        _addresses.hasCypherdata() &&
        _user.hasCypherdata()
    }

    public func signOut() {
        _credential.wipeValue()
        _salts.wipeValue()
        _passphrases.wipeValue()
        _addresses.wipeValue()
        _user.wipeValue()
        mainKeyProvider.wipeMainKey()
    }
}
