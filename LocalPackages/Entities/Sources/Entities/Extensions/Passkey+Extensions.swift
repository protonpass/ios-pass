//
// Passkey+Extensions.swift
// Proton Pass - Created on 27/02/2024.
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
//

import Foundation

public extension Passkey {
    static func from(_ response: CreatePasskeyResponse) -> Self {
        var passkey = Passkey()
        passkey.keyID = response.keyId
        passkey.content = response.passkey
        passkey.domain = response.domain
        passkey.rpID = response.rpId ?? ""
        passkey.rpName = response.rpName
        passkey.userName = response.userName
        passkey.userDisplayName = response.userDisplayName
        passkey.userID = response.userId
        passkey.createTime = UInt32(Date.now.timeIntervalSince1970)
        passkey.credentialID = response.credentialId
        passkey.userHandle = response.userHandle ?? .init()
        return passkey
    }
}
