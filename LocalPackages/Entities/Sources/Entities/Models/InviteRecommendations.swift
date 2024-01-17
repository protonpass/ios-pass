//
// InviteRecommendations.swift
// Proton Pass - Created on 14/12/2023.
// Copyright (c) 2023 Proton Technologies AG
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
//

import Foundation

public struct InviteRecommendationsQuery: Sendable {
    public let lastToken: String?
    public let pageSize: Int
    public let email: String

    public init(lastToken: String?, pageSize: Int, email: String) {
        self.lastToken = lastToken
        self.pageSize = pageSize
        self.email = email
    }
}

public struct InviteRecommendations: Sendable, Decodable, Hashable {
    public let recommendedEmails: [String]
    public let planInternalName: String?
    public let groupDisplayName: String?
    public let planRecommendedEmails: [String]
    public let planRecommendedEmailsNextToken: String?

    public var isEmpty: Bool {
        recommendedEmails.isEmpty && planRecommendedEmails.isEmpty
    }

    public func merging(with other: Self) -> Self {
        .init(recommendedEmails: other.recommendedEmails,
              planInternalName: planInternalName,
              groupDisplayName: groupDisplayName,
              planRecommendedEmails: planRecommendedEmails + other.planRecommendedEmails,
              planRecommendedEmailsNextToken: other.planRecommendedEmailsNextToken)
    }
}
