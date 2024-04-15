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

// MARK: - Breach

public struct Breach: Decodable, Equatable, Sendable {
    public let id, email: String
    public let severity: Double
    public let name: String
    public let createdAt, publishedAt: Date
    public let source: BreachSource
    public let size: Int
    public let exposedData: [BreachExposedData]
    public let passwordLastChars: String
    public let actions: [BreachAction]

    public init(id: String,
                email: String,
                severity: Double,
                name: String,
                createdAt: Date,
                publishedAt: Date,
                source: BreachSource,
                size: Int,
                exposedData: [BreachExposedData],
                passwordLastChars: String,
                actions: [BreachAction]) {
        self.id = id
        self.email = email
        self.severity = severity
        self.name = name
        self.createdAt = createdAt
        self.publishedAt = publishedAt
        self.source = source
        self.size = size
        self.exposedData = exposedData
        self.passwordLastChars = passwordLastChars
        self.actions = actions
    }
//    enum CodingKeys: String, CodingKey {
//        case id = "ID"
//        case email = "Email"
//        case severity = "Severity"
//        case name = "Name"
//        case createdAt = "CreatedAt"
//        case publishedAt = "PublishedAt"
//        case source = "Source"
//        case size = "Size"
//        case exposedData = "ExposedData"
//        case passwordLastChars = "PasswordLastChars"
//        case actions = "Actions"
//    }
}
