//
// Alias.swift
// Proton Pass - Created on 15/09/2022.
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

public struct Alias: Decodable, Sendable, Equatable, Hashable {
    public let email: String
    public let mailboxes: [AliasLinkedMailbox]
    public let availableMailboxes: [AliasLinkedMailbox]
    public let note: String?
    public let name: String?
    public let displayName: String
    public let stats: AliasStats
}

public struct AliasStats: Decodable, Sendable, Equatable, Hashable {
    // Count of emails forwarded through this alias in the last 14 days
    public let forwardedEmails: Int

    // Count of emails replied to in the last 14 days
    public let repliedEmails: Int

    // Count of emails blocked in the last 14 days
    public let blockedEmails: Int
}
