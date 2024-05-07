//
// LogInItemData+Mock.swift
// Proton Pass - Created on 28/03/2024.
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

public extension LogInItemData {
    static func mock(email: String = "MockEmail@proton.me",
                     username: String = "Mock User",
                     password: String = "password123",
                     totpUri: String = "otpauth://totp/Example:email@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example",
                     urls: [String] = ["https://example.com"],
                     allowedAndroidApps: [AllowedAndroidApp] = [],
                     passkeys: [Passkey] = []) -> LogInItemData {
        LogInItemData(email: email, 
                      username: username,
                      password: password,
                      totpUri: totpUri,
                      urls: urls,
                      allowedAndroidApps: allowedAndroidApps,
                      passkeys: passkeys)
    }
}
