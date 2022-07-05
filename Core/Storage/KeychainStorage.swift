//
// KeychainStorage.swift
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

import Foundation
import ProtonCore_Keymaker

@propertyWrapper
public final class KeychainStorage<T: Codable> {
    private weak var mainKeyProvider: MainKeyProvider?
    private weak var keychain: Keychain?
    private let key: String
    private let defaultValue: T?

    public init(key: String, defaultValue: T? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public func hasCypherdata() -> Bool {
        guard let keychain = keychain else {
            return false
        }
        return keychain.data(forKey: key) != nil
    }

    public func setKeychain(_ keychain: Keychain) {
        self.keychain = keychain
    }

    public func setMainKeyProvider(_ mainKeyProvider: MainKeyProvider) {
        self.mainKeyProvider = mainKeyProvider
    }

    public var wrappedValue: T? {
        get {
            guard let keychain = keychain else {
                PKLogger.shared?.log("Keychain is not set for key \(key). Fall back to defaultValue.")
                return defaultValue
            }

            guard let mainKeyProvider = mainKeyProvider else {
                PKLogger.shared?.log("MainKeyProvider is not set for key \(key). Fall back to defaultValue.")
                return defaultValue
            }

            guard let cypherdata = keychain.data(forKey: key) else {
                PKLogger.shared?.log("cypherdata does not exist for key \(key). Fall back to defaultValue.")
                return defaultValue
            }

            guard let mainKey = mainKeyProvider.mainKey else {
                PKLogger.shared?.log("mainKey is null for key \(key). Fall back to defaultValue.")
                return defaultValue
            }

            do {
                let lockedData = Locked<Data>(encryptedValue: cypherdata)
                let unlockedData = try lockedData.unlock(with: mainKey)
                return try JSONDecoder().decode(T.self, from: unlockedData)
            } catch {
                // Consider that the cypherdata is lost => remove it
                PKLogger.shared?.log(error)
                wipeValue()
                return defaultValue
            }
        }

        set {
            guard let keychain = keychain else {
                PKLogger.shared?.log("Keychain is not set for key \(key). Early exit.")
                return
            }

            guard let mainKeyProvider = mainKeyProvider else {
                PKLogger.shared?.log("MainKeyProvider is not set for key \(key). Early exit")
                return
            }

            guard let mainKey = mainKeyProvider.mainKey else {
                PKLogger.shared?.log("mainKey is null for key \(key). Early exit")
                return
            }

            if let newValue = newValue {
                do {
                    let data = try JSONEncoder().encode(newValue)
                    let lockedData = try Locked<Data>(clearValue: data, with: mainKey)
                    let cypherdata = lockedData.encryptedValue
                    keychain.set(cypherdata, forKey: key)
                } catch {
                    PKLogger.shared?.log(error)
                }
            } else {
                keychain.remove(forKey: key)
            }
        }
    }

    public func wipeValue() {
        keychain?.remove(forKey: key)
    }
}
