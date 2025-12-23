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

import Foundation

public struct OrganizationInviteRecommendations: Sendable, Identifiable, Decodable {
    public private(set) var groupDisplayName: String?
    public private(set) var nextToken: String?
    public private(set) var entries: [OrganizationMemberEmailSuggestion]

    public init(groupDisplayName: String?,
                nextToken: String?,
                entries: [OrganizationMemberEmailSuggestion]) {
        self.groupDisplayName = groupDisplayName
        self.nextToken = nextToken
        self.entries = entries
    }

    public var id: String { groupDisplayName ?? UUID().uuidString }

    public var canFetchMore: Bool {
        nextToken != nil || entries.isEmpty
    }

    public mutating func merge(with other: Self) {
        groupDisplayName = other.groupDisplayName ?? groupDisplayName
        nextToken = other.nextToken
        entries.append(contentsOf: other.entries)
    }

    public mutating func reset() {
        nextToken = nil
        entries.removeAll()
    }
}

public struct OrganizationMemberEmailSuggestion: Sendable, Decodable {
    public let email: String
}
