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
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Networking

extension LockedKeychainStorage {
    /// Conveniently initialize with injected `keychain`, `mainKeyProvider` & `logManager`
    convenience init(key: Key, defaultValue: T? = nil) {
        self.init(key: key,
                  defaultValue: defaultValue,
                  keychain: SharedToolingContainer.shared.keychain(),
                  mainKeyProvider: SharedToolingContainer.shared.mainKeyProvider(),
                  logManager: SharedToolingContainer.shared.logManager())
    }
}

final class AppData {
    @LockedKeychainStorage(key: .userData)
    var userData: UserData?

    @LockedKeychainStorage(key: .unauthSessionCredentials)
    var unauthSessionCredentials: AuthCredential?

    @LockedKeychainStorage(key: .symmetricKey)
    private var symmetricKey: String?

    init() {}

    func getSymmetricKey() throws -> SymmetricKey {
        if let symmetricKey {
            if symmetricKey.count == 32 {
                // Legacy path with 32-character long string
                guard let symmetricKeyData = symmetricKey.data(using: .utf8) else {
                    throw PPError.failedToGetOrCreateSymmetricKey
                }
                // Update the legacy key to the new model
                self.symmetricKey = symmetricKeyData.encodeBase64()
                return .init(data: symmetricKeyData)
            } else {
                // New path with base 64 string
                guard let symmetricKeyData = try symmetricKey.base64Decode() else {
                    throw PPError.failedToGetOrCreateSymmetricKey
                }
                return .init(data: symmetricKeyData)
            }
        } else {
            let randomData = try Data.random()
            symmetricKey = randomData.encodeBase64()
            return .init(data: randomData)
        }
    }
}
