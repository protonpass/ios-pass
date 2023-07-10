//
// KeychainStorage.swift
// Proton Pass - Created on 09/07/2023.
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
import ProtonCore_Keymaker

/// Read/write from keychain with no lock mechanism
@propertyWrapper
public struct KeychainStorage<Value: Codable> {
    private let key: String
    private var defaultValue: Value
    private let keychain: KeychainProtocol
    private let logger: Logger

    public init(key: String,
                defaultValue: Value,
                keychain: KeychainProtocol,
                logManager: LogManager) {
        self.key = key
        self.defaultValue = defaultValue
        self.keychain = keychain
        logger = .init(manager: logManager)
    }

    public var wrappedValue: Value {
        get {
            if let data = keychain.data(forKey: key) {
                do {
                    return try JSONDecoder().decode(Value.self, from: data)
                } catch {
                    logger.error("Corrupted data for key \(key). Fall back to defaultValue")
                    logger.error(error)
                    return defaultValue
                }
            } else {
                logger.debug("No value for key \(key). Fall back to defaultValue")
                return defaultValue
            }
        }

        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                // Set to nil => remove from keychain
                keychain.remove(forKey: key)
            } else {
                do {
                    let data = try JSONEncoder().encode(newValue)
                    keychain.set(data, forKey: key)
                } catch {
                    logger.error("Failed to serialize data for key \(key) \(error.localizedDescription)")
                }
            }
        }
    }
}
