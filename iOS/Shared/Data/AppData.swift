//
// AppData.swift
// Proton Pass - Created on 01/04/2023.
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

import Client
import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking

private extension LockedKeychainStorage {
    /// Conveniently initialize with injected `keychain`, `mainKeyProvider` & `logManager`
    init(key: any RawRepresentable<String>, defaultValue: Value) {
        self.init(key: key.rawValue,
                  defaultValue: defaultValue,
                  keychain: SharedToolingContainer.shared.keychain(),
                  mainKeyProvider: SharedToolingContainer.shared.mainKeyProvider(),
                  logManager: SharedToolingContainer.shared.logManager())
    }
}

enum AppDataKey: String {
    case userData
    case unauthSessionCredentials
    case symmetricKey
}

final class AppData: UserDataProvider, SymmetricKeyProvider {
    @LockedKeychainStorage(key: AppDataKey.userData, defaultValue: nil)
    private var userData: UserData? {
        didSet {
            cachedUserData = nil
        }
    }

    @LockedKeychainStorage(key: AppDataKey.unauthSessionCredentials, defaultValue: nil)
    private var unauthSessionCredentials: AuthCredential?

    @LockedKeychainStorage(key: AppDataKey.symmetricKey, defaultValue: nil)
    private var symmetricKey: String? {
        didSet {
            cachedSymmetricKey = nil
        }
    }

    /// Reading from keychain is expensive so we cache `userData` & `symmetricKey`
    /// so we always serve cached results until values are updated in keychain
    private var cachedUserData: UserData??
    private var cachedSymmetricKey: SymmetricKey?

    init() {}

    func getSymmetricKey() throws -> SymmetricKey {
        if let cachedSymmetricKey {
            return cachedSymmetricKey
        }
        let symmetricKey = try getOrCreateSymmetricKey()
        cachedSymmetricKey = symmetricKey
        return symmetricKey
    }

    func removeSymmetricKey() {
        symmetricKey = nil
    }

    func setUserData(_ userData: UserData?) {
        self.userData = userData
    }

    func getUserData() -> UserData? {
        if let cachedUserData {
            return cachedUserData
        }
        cachedUserData = userData
        return userData
    }

    func setUnauthCredential(_ credential: AuthCredential?) {
        unauthSessionCredentials = credential
    }

    func getUnauthCredential() -> AuthCredential? {
        unauthSessionCredentials
    }
}

private extension AppData {
    func getOrCreateSymmetricKey() throws -> SymmetricKey {
        if let symmetricKey {
            guard let symmetricKeyData = try symmetricKey.base64Decode() else {
                throw PassError.failedToGetOrCreateSymmetricKey
            }
            return .init(data: symmetricKeyData)
        } else {
            let randomData = try Data.random()
            symmetricKey = randomData.encodeBase64()
            return .init(data: randomData)
        }
    }
}
