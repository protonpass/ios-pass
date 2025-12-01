//
// OrganizationRecommendations.swift
// Proton Pass - Created on 06/11/2025.
// Copyright (c) 2025 Proton Technologies AG
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

public struct OrganizationInviteRecommendations: Sendable, Identifiable, Decodable {
    public let groupDisplayName: String
    public let nextToken: String?
    public let entries: [OrganizationMemberEmailSuggestion]

    public init(groupDisplayName: String, nextToken: String?, entries: [OrganizationMemberEmailSuggestion]) {
        self.groupDisplayName = groupDisplayName
        self.nextToken = nextToken
        self.entries = entries
    }

    public var id: String { groupDisplayName }

    public var reset: OrganizationInviteRecommendations {
        OrganizationInviteRecommendations(groupDisplayName: groupDisplayName,
                                          nextToken: nil,
                                          entries: [])
    }
}

public struct OrganizationMemberEmailSuggestion: Sendable, Identifiable, Decodable {
    public let email: String

    public init(email: String) {
        self.email = email
    }

    public var id: String { email }
}
