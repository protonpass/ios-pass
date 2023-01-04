//
// KeychainStorage.swift
// Proton Pass - Created on 04/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Foundation
import ProtonCore_Keymaker

@propertyWrapper
public final class KeychainStorage<T: Codable> {
    private weak var mainKeyProvider: MainKeyProvider?
    private weak var keychain: Keychain?
    private var logger: LoggerV2?
    private let key: Key
    private let defaultValue: T?

    public init(key: Key, defaultValue: T? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public func hasCypherdata() -> Bool {
        guard let keychain else {
            return false
        }
        return keychain.data(forKey: key.rawValue) != nil
    }

    public func setKeychain(_ keychain: Keychain) {
        self.keychain = keychain
    }

    public func setMainKeyProvider(_ mainKeyProvider: MainKeyProvider) {
        self.mainKeyProvider = mainKeyProvider
    }

    public func setLogManager(_ logManager: LogManager) {
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }

    public var wrappedValue: T? {
        get {
            let keyRawValue = key.rawValue
            guard let keychain else {
                logger?.warning("Keychain is not set for key \(keyRawValue). Fall back to defaultValue.")
                return defaultValue
            }

            guard let mainKeyProvider else {
                logger?.warning("MainKeyProvider is not set for key \(keyRawValue). Fall back to defaultValue.")
                return defaultValue
            }

            guard let cypherdata = keychain.data(forKey: keyRawValue) else {
                logger?.warning("cypherdata does not exist for key \(keyRawValue). Fall back to defaultValue.")
                return defaultValue
            }

            guard let mainKey = mainKeyProvider.mainKey else {
                logger?.warning("mainKey is null for key \(keyRawValue). Fall back to defaultValue.")
                return defaultValue
            }

            do {
                let lockedData = Locked<Data>(encryptedValue: cypherdata)
                let unlockedData = try lockedData.unlock(with: mainKey)
                return try JSONDecoder().decode(T.self, from: unlockedData)
            } catch {
                // Consider that the cypherdata is lost => remove it
                logger?.error(error)
                wipeValue()
                return defaultValue
            }
        }

        set {
            let keyRawValue = key.rawValue
            guard let keychain else {
                logger?.warning("Keychain is not set for key \(key). Early exit.")
                return
            }

            guard let mainKeyProvider else {
                logger?.warning("MainKeyProvider is not set for key \(key). Early exit")
                return
            }

            guard let mainKey = mainKeyProvider.mainKey else {
                logger?.warning("mainKey is null for key \(key). Early exit")
                return
            }

            if let newValue {
                do {
                    let data = try JSONEncoder().encode(newValue)
                    let lockedData = try Locked<Data>(clearValue: data, with: mainKey)
                    let cypherdata = lockedData.encryptedValue
                    keychain.set(cypherdata, forKey: keyRawValue)
                } catch {
                    logger?.error(error)
                }
            } else {
                keychain.remove(forKey: keyRawValue)
            }
        }
    }

    public func wipeValue() {
        keychain?.remove(forKey: key.rawValue)
    }
}

// swiftlint:disable type_name
// swiftlint:disable explicit_enum_raw_value
public extension KeychainStorage {
    enum Key: String {
        case sessionData
        case symmetricKey
    }
}
