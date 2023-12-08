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
import Foundation
import ProtonCoreKeymaker

/**
 Property wrapper has 2 mechanism:
 - Wrap via `wrappedValue` property. We do additional logic inside the getter and setter of this property.
 - Wrap via a subscript (be aware that the subscript must respect the function signature, otherwise the compliler wouldn't take it into account)

 We need a property wrapper that does the following:
 - Read/write from keychain instead of a short-live value on memory => inject `KeychainProtocol`
 - Support optional value => `AnyOptional` protocol
 - Support default value => `defaultValue` property
 - Announce changes to enclosing instance like SwiftUI's `@AppStorage` => subscript mechanism instead of `wrappedValue`

 More technical detail: https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/
 */

/// Read/write from keychain with no lock mechanism
@propertyWrapper
public struct KeychainStorage<Value: Codable> {
    private let key: String
    private var defaultValue: Value
    private let keychain: any KeychainProtocol
    private let logger: Logger

    public init(key: String,
                defaultValue: Value,
                keychain: any KeychainProtocol,
                logManager: any LogManagerProtocol) {
        self.key = key
        self.defaultValue = defaultValue
        self.keychain = keychain
        logger = .init(manager: logManager)
    }

    /// Two reasons for this:
    /// 1. We have to have a property named `wrappedValue` otherwise we'll run into
    /// "Property wrapper type '<name>' does not contain a non-static property named 'wrappedValue'"
    ///
    /// 2. Trick the compiler that we have `get` and `set` otherwise we'll run into
    /// "Cannot assign to property: '<name>' is a get-only property"
    @available(*, unavailable, message: "@KeychainStorage can only be applied to classes")
    public var wrappedValue: Value {
        get { fatalError("Not applicable") }
        set { fatalError("Not applicable") } // swiftlint:disable:this unused_setter_value
    }

    /// The wrapped value used by the subscript. The name doesn't have to be `stored`.
    /// We cannot use the name `wrappedValue` because that would imply the `wrappedValue` mechanism instead of
    /// subcript one
    private var stored: Value {
        get {
            // Get serialized data from keychain and then deserialize
            if let data = keychain.data(forKey: key) {
                do {
                    return try JSONDecoder().decode(Value.self, from: data)
                } catch {
                    logger.error("Corrupted data for key \(key). Fall back to defaultValue")
                    logger.error(error)
                    keychain.remove(forKey: key)
                    return defaultValue
                }
            } else {
                logger.debug("No value for key \(key). Fall back to defaultValue")
                return defaultValue
            }
        }

        set {
            // Check if the newValue is nil or not
            // If nil, remove the data from keychain
            // If not nil, serialize and save to keychain
            if let optional = newValue as? (any AnyOptional), optional.isNil {
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

    public static subscript<T>(_enclosingInstance instance: T,
                               wrapped wrappedKeyPath: ReferenceWritableKeyPath<T,
                                   Value>,
                               storage storageKeyPath: ReferenceWritableKeyPath<T,
                                   Self>)
        -> Value {
        get {
            instance[keyPath: storageKeyPath].stored
        }
        set {
            instance[keyPath: storageKeyPath].stored = newValue
            if let observableObject = instance as? any ObservableObject {
                let publisher = observableObject.objectWillChange as any Publisher
                (publisher as? ObservableObjectPublisher)?.send()
            }
        }
    }
}
