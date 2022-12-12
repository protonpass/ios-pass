//
//  TestUser.swift
//  ProtonCore-TestingToolkig - Created on 23.04.21.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
#if canImport(SwiftOTP)
import SwiftOTP
#endif
import ProtonCore_Log

public class TestUser {
    
    public var email: String
    public var password: String
    public var mailboxPassword: String
    public var twoFASecurityKey: String
    public var username: String
    public var pmMeEmail: String
    
    public init(email: String, password: String, mailboxPassword: String, twoFASecurityKey: String) {
        self.email = email
        self.password = password
        self.mailboxPassword = mailboxPassword
        self.twoFASecurityKey = twoFASecurityKey
        self.username = String(email.split(separator: "@")[0])
        self.pmMeEmail = "\(username)@pm.me"
    }
    
    public init(user: String) {
        let userData = user.split(separator: ",")
        self.email = String(userData[0])
        self.password = String(userData[1])
        self.mailboxPassword = String(userData[2])
        self.twoFASecurityKey = String(userData[3])
        self.username = String(String(userData[0]).split(separator: "@")[0])
        self.pmMeEmail = "\(username)@pm.me"
    }
    
    #if canImport(SwiftOTP)
    public func generateCode() -> String {
        let totp = TOTP(secret: base32DecodeToData(twoFASecurityKey)!)
        
        if let res = totp?.generate(time: Date()) {
            return res
        }
        return ""
    }
    #endif
}
