//
// LockedKeychainStorage.swift
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
import ProtonCoreKeymaker

/// Read/write from keychain with lock mechanism provided by `MainKeyProvider`
@propertyWrapper
public struct LockedKeychainStorage<Value: Codable> {
    private let key: String
    private let defaultValue: Value
    private let mainKeyProvider: any MainKeyProvider
    private let keychain: any KeychainProtocol
    private let logger: Logger

    public init(key: String,
                defaultValue: Value,
                keychain: any KeychainProtocol,
                mainKeyProvider: any MainKeyProvider,
                logManager: any LogManagerProtocol) {
        self.key = key
        self.defaultValue = defaultValue
        self.keychain = keychain
        self.mainKeyProvider = mainKeyProvider
        logger = .init(manager: logManager)
    }

    public var wrappedValue: Value {
        get {
            do {
                return try getValue(for: key)
            } catch {
                logger.debug("Error retrieving data for key \(key). Fallback to default value.")
                logger.error(error)
                return defaultValue
            }
        }

        set {
            do {
                try setValue(newValue, for: key)
            } catch {
                logger.error("Error setting data for key \(key) \(error.localizedDescription)")
            }
        }
    }
}

private extension LockedKeychainStorage {
    func getValue(for key: String) throws -> Value {
        guard let cypherdata = try keychain.dataOrError(forKey: key) else {
            logger.warning("cypherdata does not exist for key \(key). Fall back to defaultValue.")
            return defaultValue
        }

        guard let mainKey = mainKeyProvider.mainKey else {
            logger.warning("mainKey is null for key \(key). Fall back to defaultValue.")
            return defaultValue
        }

        do {
            let lockedData = Locked<Data>(encryptedValue: cypherdata)
            let unlockedData = try lockedData.unlock(with: mainKey)
            return try JSONDecoder().decode(Value.self, from: unlockedData)
        } catch {
            // Consider that the cypherdata is lost => remove it
            logger.error("Corrupted data for key \(key). Fall back to defaultValue.")
            logger.error(error)
            try keychain.removeOrError(forKey: key)
            return defaultValue
        }
    }

    func setValue(_ value: Value, for key: String) throws {
        guard let mainKey = mainKeyProvider.mainKey else {
            logger.warning("mainKey is null for key \(key). Early exit")
            return
        }

        if let optional = value as? (any AnyOptional), optional.isNil {
            // Set to nil => remove from keychain
            try keychain.removeOrError(forKey: key)
        } else {
            do {
                let data = try JSONEncoder().encode(value)
                let lockedData = try Locked<Data>(clearValue: data, with: mainKey)
                let cypherdata = lockedData.encryptedValue
                try keychain.setOrError(cypherdata, forKey: key)
            } catch {
                logger.error("Failed to serialize data for key \(key) \(error.localizedDescription)")
            }
        }
    }
}
