//
// UserDefaultService.swift
// Proton Pass - Created on 22/01/2024.
// Copyright (c) 2024 Proton Technologies AG
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

public protocol UserDefaultPersistency {
    func set<T>(value: T, forKey key: UserDefaultsKey) throws
    func value<T>(forKey key: UserDefaultsKey) -> T?
    func remove(forKey key: UserDefaultsKey)
}

public enum UserDefaultsKey: String, Sendable {
    case settings
}

public enum UserDefaultsError: Error {
    case invalidType
}

public final class UserDefaultService: UserDefaultPersistency {
    private let defaults: UserDefaults

    public init(appGroup: String) {
        defaults = UserDefaults(suiteName: appGroup) ?? .standard
    }

    public func set(value: some Any, forKey key: UserDefaultsKey) throws {
        guard isValidType(value) else {
            throw UserDefaultsError.invalidType
        }
        defaults.set(value, forKey: key.rawValue)
    }

    public func value<T>(forKey key: UserDefaultsKey) -> T? {
        defaults.object(forKey: key.rawValue) as? T
    }

    public func remove(forKey key: UserDefaultsKey) {
        defaults.removeObject(forKey: key.rawValue)
    }
}

private extension UserDefaultService {
    func isValidType(_ value: some Any) -> Bool {
        value is NSData || value is NSString || value is NSNumber ||
            value is NSDate || value is NSArray || value is NSDictionary
    }
}
