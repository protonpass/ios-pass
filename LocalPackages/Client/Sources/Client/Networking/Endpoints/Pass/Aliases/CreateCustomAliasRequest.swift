//
// CreateCustomAliasRequest.swift
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

import Entities

public struct AliasCreationInfo: Sendable {
    let prefix: String
    let suffix: Suffix
    public let mailboxIds: [Int]

//    var aliasAddress: String { prefix + suffix.suffix }

    public init(prefix: String, suffix: Suffix, mailboxIds: [Int]) {
        self.prefix = prefix
        self.suffix = suffix
        self.mailboxIds = mailboxIds
    }
}

public struct CreateCustomAliasRequest: Sendable {
    /// Prefix for the alias to be created (prefix.xxx@domain.com)
    public let prefix: String

    /// Signed suffix for the alias to be created (xxx.asdaa3@domain.com.signature)
    public let signedSuffix: String

    /// IDs for the mailboxes that will receive emails sent to this alias
    public let mailboxIDs: [Int]

    public let item: CreateItemRequest

    public init(info: AliasCreationInfo, item: CreateItemRequest) {
        prefix = info.prefix
        signedSuffix = info.suffix.signedSuffix
        mailboxIDs = info.mailboxIds
        self.item = item
    }
}

extension CreateCustomAliasRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case prefix = "Prefix"
        case signedSuffix = "SignedSuffix"
        case mailboxIDs = "MailboxIDs"
        case item = "Item"
    }
}
