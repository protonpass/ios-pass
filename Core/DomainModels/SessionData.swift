//
// SessionData.swift
// Proton Pass - Created on 23/07/2022.
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

import ProtonCore_Login

/// All the needed data for the app to function in logged in mode
/// Conform to `Codable` so it can be serialized/deserialized and saved to `Keychain`
/// via `KeychainStorage` property wrapper
public final class SessionData: Codable {
    public let userData: UserData

    public init(userData: UserData) {
        self.userData = userData
    }
}

public extension SessionData {
    static var preview: SessionData { .init(userData: .preview) }
}
