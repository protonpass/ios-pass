//
// PPKeychain.swift
// Proton Pass - Created on 03/07/2022.
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

public protocol KeychainProtocol: AnyObject, Sendable {
    // Getters
    func data(forKey key: String, attributes: [CFString: Any]?) -> Data?
    func string(forKey key: String, attributes: [CFString: Any]?) -> String?

    // Setters
    func set(_ data: Data, forKey key: String, attributes: [CFString: Any]?)
    func set(_ string: String, forKey key: String, attributes: [CFString: Any]?)

    // Cleaner
    func remove(forKey key: String)
}

extension KeychainProtocol {
    // Getters
    func data(forKey key: String, attributes: [CFString: Any]? = nil) -> Data? {
        data(forKey: key, attributes: attributes)
    }

    func string(forKey key: String, attributes: [CFString: Any]? = nil) -> String? {
        string(forKey: key, attributes: attributes)
    }

    // Setters
    func set(_ data: Data, forKey key: String, attributes: [CFString: Any]? = nil) {
        set(data, forKey: key, attributes: attributes)
    }

    func set(_ string: String, forKey key: String, attributes: [CFString: Any]? = nil) {
        set(string, forKey: key, attributes: attributes)
    }
}

extension Keychain: @unchecked Sendable, KeychainProtocol {}

public final class PPKeychain: Keychain {
    public init() {
        super.init(service: "ch.protonmail", accessGroup: Constants.keychainGroup)
    }
}

extension PPKeychain: SettingsProvider {
    private static let LockTimeKey = "PPKeychain.LockTimeKey"

    public var lockTime: AutolockTimeout {
        get {
            guard let string = string(forKey: Self.LockTimeKey), let intValue = Int(string) else {
                return .never
            }
            return AutolockTimeout(rawValue: intValue)
        }
        set {
            set(String(newValue.rawValue), forKey: Self.LockTimeKey)
        }
    }
}
