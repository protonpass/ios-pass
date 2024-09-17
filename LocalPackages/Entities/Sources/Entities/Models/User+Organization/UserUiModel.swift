//
// UserUiModel.swift
// Proton Pass - Created on 05/09/2024.
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
//

public struct UserUiModel: Sendable, Identifiable, Hashable {
    public let id: String
    public let displayName: String?
    public let email: String?
    public let plan: Plan

    public init(id: String,
                displayName: String?,
                email: String?,
                plan: Plan) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.plan = plan
    }

    public var displayNameAndEmail: String {
        if let displayName {
            if let email {
                return "\(displayName) (\(email))"
            }
            return displayName
        }
        return email ?? ""
    }

    public var emailWithoutDomain: String? {
        email?.components(separatedBy: "@").first
    }
}
