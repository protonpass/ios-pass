//
//  ObfuscatedConstants.swift
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

public class TestData {
    public init() { }
    
    public var onePassUser = TestUser(email: ObfuscatedConstants.onePassUserUsername, password: ObfuscatedConstants.onePassUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var twoPassUser = TestUser(email: ObfuscatedConstants.twoPassUserUsername, password: ObfuscatedConstants.twoPassUserPassword, mailboxPassword: ObfuscatedConstants.twoPassUserMailboxPassword, twoFASecurityKey: "")
    public var onePassUserWith2Fa = TestUser(email: ObfuscatedConstants.onePassUserWith2FaUsername, password: ObfuscatedConstants.onePassUserWith2FaPassword, mailboxPassword: "", twoFASecurityKey: ObfuscatedConstants.onePassUserWith2FatwoFASecurityKey)
    public var twoPassUserWith2Fa = TestUser(email: ObfuscatedConstants.twoPassUserWith2FaUsername, password: ObfuscatedConstants.twoPassUserWith2FaPassword, mailboxPassword: ObfuscatedConstants.twoPassUserWith2FaMailboxPassword, twoFASecurityKey: ObfuscatedConstants.twoPassUserWith2FatwoFASecurityKey)
    public var disabledUser = TestUser(email: ObfuscatedConstants.disabledUserUsername, password: ObfuscatedConstants.disabledUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var vpnFreeUser = TestUser(email: ObfuscatedConstants.vpnFreeUserUsername, password: ObfuscatedConstants.vpnFreeUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var vpnBasicUser = TestUser(email: ObfuscatedConstants.vpnBasicUserUsername, password: ObfuscatedConstants.vpnBasicUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var vpnPlusUser = TestUser(email: ObfuscatedConstants.vpnPlusUserUsername, password: ObfuscatedConstants.vpnPlusUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var orgAdminUser = TestUser(email: ObfuscatedConstants.orgAdminUserUsername, password: ObfuscatedConstants.orgAdminUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var orgPrivateUser = TestUser(email: ObfuscatedConstants.orgPrivateUserUsername, password: ObfuscatedConstants.orgPrivateUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var orgPublicUser = TestUser(email: ObfuscatedConstants.orgPublicUserUsername, password: ObfuscatedConstants.orgPublicUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var orgNewPrivateUser = TestUser(email: ObfuscatedConstants.orgNewPrivateUserEmail, password: ObfuscatedConstants.orgNewPrivateUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var usernameVpnFreeUser = TestUser(email: ObfuscatedConstants.usernameVpnFreeUserEmail, password: ObfuscatedConstants.usernameVpnFreeUserPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var mailFreeUser = TestUser(email: ObfuscatedConstants.mailFreeUsername, password: ObfuscatedConstants.mailFreePassword, mailboxPassword: "", twoFASecurityKey: "")
    public var mailPlusUser = TestUser(email: ObfuscatedConstants.mailPlusUsername, password: ObfuscatedConstants.mailPlusPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var mailProUser = TestUser(email: ObfuscatedConstants.mailProUsername, password: ObfuscatedConstants.mailProPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var visionaryUser = TestUser(email: ObfuscatedConstants.visionaryUsername, password: ObfuscatedConstants.visionaryPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var mailPlusVpnPlusWithCouponUser = TestUser(email: ObfuscatedConstants.mailPlusVpnPlusWithCouponUsername, password: ObfuscatedConstants.mailPlusVpnPlusWithCouponPassword, mailboxPassword: "", twoFASecurityKey: "")
    public var mailprovpnfreeUser = TestUser(email: ObfuscatedConstants.mailProVpnFreeUsername, password: ObfuscatedConstants.mailProVpnFreePassword, mailboxPassword: "", twoFASecurityKey: "")
    public var mailplusvpnfreeUser = TestUser(email: ObfuscatedConstants.mailPlusVpnFreeUsername, password: ObfuscatedConstants.mailPlusVpnFreePassword, mailboxPassword: "", twoFASecurityKey: "")
    public var orgSubUser = TestUser(email: ObfuscatedConstants.orgSubUserUsername, password: ObfuscatedConstants.orgSubUserPassword, mailboxPassword: "", twoFASecurityKey: "")
}
