//
// PKKeychain.swift
// Proton Key - Created on 03/07/2022.
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

import ProtonCore_Keymaker

public final class PKKeychain: Keychain {
    public static let shared = PKKeychain(service: "me.proton.pass", accessGroup: Constants.keychainGroup)
}

extension PKKeychain: SettingsProvider {
    private static let LockTimeKey = "PKKeychain.LockTimeKey"

    public var lockTime: AutolockTimeout {
        get {
            guard let string = self.string(forKey: Self.LockTimeKey), let intValue = Int(string) else {
                return .never
            }
            return AutolockTimeout(rawValue: intValue)
        }
        set {
            self.set(String(newValue.rawValue), forKey: Self.LockTimeKey)
        }
    }
}
