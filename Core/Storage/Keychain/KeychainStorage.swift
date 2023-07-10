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
import SwiftUI

/// Read/write from keychain with no lock mechanism
@propertyWrapper
public struct KeychainStorage<Value: Codable>: DynamicProperty {
    private var value: Value
    private let key: String
    private let keychain: KeychainProtocol
    private let logger: Logger

    public init(wrappedValue: Value,
                key: String,
                keychain: KeychainProtocol,
                logManager: LogManager) {
        value = wrappedValue
        self.key = key
        self.keychain = keychain
        logger = .init(manager: logManager)
    }

    public var wrappedValue: Value {
        get {
            if let data = keychain.data(forKey: key) {
                do {
                    return try JSONDecoder().decode(Value.self, from: data)
                } catch {
                    logger.warning("Corrupted data for key \(key), fall back to default value")
                    logger.error(error)
                    return value
                }
            } else {
                logger.debug("No value for key \(key), fall back to default value")
                return value
            }
        }

        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                keychain.remove(forKey: key)
                value = newValue
            } else {
                do {
                    let data = try JSONEncoder().encode(newValue)
                    keychain.set(data, forKey: key)
                    value = newValue
                } catch {
                    logger.error(error)
                }
            }
        }
    }

    /// Trigger `objectWillChange` of enclosing instance
    /// https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/
    public static subscript<T: ObservableObject>(_enclosingInstance instance: T,
                                                 wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
                                                 storage storageKeyPath: ReferenceWritableKeyPath<T, Self>)
        -> Value {
        get {
            instance[keyPath: storageKeyPath].value
        }
        set {
            instance[keyPath: storageKeyPath].value = newValue
            let publisher = instance.objectWillChange
            (publisher as? ObservableObjectPublisher)?.send()
        }
    }
}

// Since our property wrapper's Value type isn't optional, but
// can still contain nil values, we'll have to introduce this
// protocol to enable us to cast any assigned value into a type
// that we can compare against nil
// https://www.swiftbysundell.com/articles/property-wrappers-in-swift/
private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
