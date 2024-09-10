//
// UserBreaches.swift
// Proton Pass - Created on 10/04/2024.
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

public struct UserBreaches: Decodable, Equatable, Sendable, Hashable {
    public let emailsCount: Int
    public let domainsPeek: [BreachedDomain]
    public let addresses: [ProtonAddress]
    public let customEmails: [CustomEmail]
    public let hasCustomDomains: Bool

    public init(emailsCount: Int,
                domainsPeek: [BreachedDomain],
                addresses: [ProtonAddress],
                customEmails: [CustomEmail],
                hasCustomDomains: Bool) {
        self.emailsCount = emailsCount
        self.domainsPeek = domainsPeek
        self.addresses = addresses
        self.customEmails = customEmails
        self.hasCustomDomains = hasCustomDomains
    }

    public static var `default`: UserBreaches {
        UserBreaches(emailsCount: 0,
                     domainsPeek: [],
                     addresses: [],
                     customEmails: [],
                     hasCustomDomains: false)
    }

    public var breached: Bool {
        emailsCount > 0
    }

    public var latestBreach: BreachedDomain? {
        domainsPeek.max()
    }

    public var verifiedCustomEmails: [CustomEmail] {
        customEmails.filter(\.verified)
    }

    public var unverifiedCustomEmails: [CustomEmail] {
        customEmails.filter { !$0.verified }
    }

//    public var hasBreachedAddresses: Bool {
//        !breachedAddresses.isEmpty
//    }

//    public var breachedAddresses: [ProtonAddress] {
//        addresses.filter { /* $0.breachCounter > 0 && */ !$0.monitoringDisabled }
//    }

    public var monitoredAddresses: [ProtonAddress] {
        addresses.filter { !$0.monitoringDisabled }
    }
}
