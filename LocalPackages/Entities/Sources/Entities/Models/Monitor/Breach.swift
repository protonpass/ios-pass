//
// Breach.swift
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

public struct Breach: Decodable, Equatable, Sendable, Identifiable, Hashable {
    public let id: String
    public let email: String

    /// The follow int has 3 values
    /// 1 - unread
    /// 2 - read
    /// 3 - resolved
    /// So for us 1&2 means unresolved and 3 resolved
    public let resolvedState: Int
    public let severity: Double
    public let name: String
    public let createdAt, publishedAt: String
    public let size: Int?
    public let exposedData: [BreachExposedData]
    public let passwordLastChars: String?
    public let actions: [BreachAction]

    public init(id: String,
                email: String,
                resolvedState: Int,
                severity: Double,
                name: String,
                createdAt: String,
                publishedAt: String,
                size: Int?,
                exposedData: [BreachExposedData],
                passwordLastChars: String?,
                actions: [BreachAction]) {
        self.id = id
        self.email = email
        self.severity = severity
        self.name = name
        self.resolvedState = resolvedState
        self.createdAt = createdAt
        self.publishedAt = publishedAt
        self.size = size
        self.exposedData = exposedData
        self.passwordLastChars = passwordLastChars
        self.actions = actions
    }

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case email
        case resolvedState
        case severity
        case name
        case createdAt
        case publishedAt
        case size
        case exposedData
        case passwordLastChars
        case actions
    }

    public var isResolved: Bool {
        resolvedState == 3
    }
}

public extension Breach {
    var publishedAtDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: publishedAt) ?? .now
    }

    var breachDate: String {
        publishedAtDate.formatted(date: .abbreviated, time: .omitted)
    }
}

public extension [Breach] {
    var allResolvedBreaches: [Breach] {
        filter(\.isResolved)
    }

    var allUnresolvedBreaches: [Breach] {
        filter { !$0.isResolved }
    }
}
