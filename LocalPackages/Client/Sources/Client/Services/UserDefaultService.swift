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

import Entities
import Foundation

public protocol UserDefaultPersistency: Sendable {
    func set(value: some Any, forKey key: UserDefaultsKey, and id: String) throws
    func value<T>(forKey key: UserDefaultsKey, and id: String) -> T?
//    func remove(forKey key: UserDefaultsKey, and id: String)
}

public enum UserDefaultsKey: String, Sendable {
    case settings
}

public final class UserDefaultService: @unchecked Sendable, UserDefaultPersistency {
    private let defaults: UserDefaults

    public init(appGroup: String) {
        defaults = UserDefaults(suiteName: appGroup) ?? .standard
    }

    public func set(value: some Any, forKey key: UserDefaultsKey, and id: String) throws {
        guard isValidType(value) else {
            throw PassError.userDefault(.invalidType)
        }
        defaults.set(value, forKey: id.userSpecificKey(with: key))
    }

    public func value<T>(forKey key: UserDefaultsKey, and id: String) -> T? {
        defaults.object(forKey: id.userSpecificKey(with: key)) as? T
    }

//    public func remove(forKey key: UserDefaultsKey, and id: String) {
//        defaults.removeObject(forKey: id.userSpecificKey(with: key))
//    }
}

private extension UserDefaultService {
    func isValidType(_ value: some Any) -> Bool {
        value is NSData || value is NSString || value is NSNumber ||
            value is NSDate || value is NSArray || value is NSDictionary
    }
}

private extension String {
    func userSpecificKey(with key: UserDefaultsKey) -> String {
        "\(self)-\(key.rawValue)"
    }
}
