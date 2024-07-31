//
// PendingAlias.swift
// Proton Pass - Created on 31/07/2024.
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

public struct PendingAlias: Decodable, Sendable {
    public let pendingAliasID: String
    public let aliasEmail: String
    public let aliasNote: String

    public init(pendingAliasID: String, aliasEmail: String, aliasNote: String) {
        self.pendingAliasID = pendingAliasID
        self.aliasEmail = aliasEmail
        self.aliasNote = aliasNote
    }
}

public struct PaginatedPendingAliases: Decodable, Sendable {
    public let total: Int
    public let lastToken: String?
    public let aliases: [PendingAlias]

    public init(total: Int, lastToken: String?, aliases: [PendingAlias]) {
        self.total = total
        self.lastToken = lastToken
        self.aliases = aliases
    }
}
