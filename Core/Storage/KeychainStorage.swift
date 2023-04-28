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
    private weak var keychain: KeychainProtocol?
    private var logger: Logger?
    private let key: Key
    private let defaultValue: T?

    public init(key: Key, defaultValue: T? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }

    // We can not set those dependencies at the moment of initializing the property wrapper
    // so we need to inject once the initialization process is done
    public func inject(keychain: KeychainProtocol, mainKeyProvider: MainKeyProvider, logManager: LogManager) {
        self.keychain = keychain
        self.mainKeyProvider = mainKeyProvider
        self.logger = .init(manager: logManager)
    }

    public var wrappedValue: T? {
        get {
            assert(logger != nil)
            let keyRawValue = key.rawValue

            assert(keychain != nil)
            guard let keychain else {
                logger?.warning("Keychain is not set for key \(keyRawValue). Fall back to defaultValue.")
                return defaultValue
            }

            assert(mainKeyProvider != nil)
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
            assert(logger != nil)

            let keyRawValue = key.rawValue

            assert(keychain != nil)
            guard let keychain else {
                logger?.warning("Keychain is not set for key \(keyRawValue). Early exit.")
                return
            }

            assert(mainKeyProvider != nil)
            guard let mainKeyProvider else {
                logger?.warning("MainKeyProvider is not set for key \(keyRawValue). Early exit")
                return
            }

            guard let mainKey = mainKeyProvider.mainKey else {
                logger?.warning("mainKey is null for key \(keyRawValue). Early exit")
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
        assert(keychain != nil)
        keychain?.remove(forKey: key.rawValue)
    }
}

public extension KeychainStorage {
    enum Key: String {
        case userPlan
        case userData
        case unauthSessionCredentials
        case symmetricKey
    }
}
