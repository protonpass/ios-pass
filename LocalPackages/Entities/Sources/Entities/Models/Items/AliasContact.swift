//
// AliasContact.swift
// Proton Pass - Created on 02/10/2024.
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

public struct AliasContact: Decodable, Sendable, Equatable, Hashable, Identifiable {
    // Should not rename to "id" otherwise decode process breaks
    public let ID: Int
    public let name: String?
    public let blocked: Bool
    public let reverseAlias: String
    public let email: String

    public init(ID: Int, name: String?, blocked: Bool, reverseAlias: String, email: String) {
        self.ID = ID
        self.name = name
        self.blocked = blocked
        self.reverseAlias = reverseAlias
        self.email = email
    }

    public var id: Int {
        // swiftformat:disable:next redundantSelf
        self.ID
    }
}
