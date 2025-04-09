//
// GeneratedPassword.swift
// Proton Pass - Created on 09/04/2025.
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

public struct GeneratedPassword: Sendable {
    public let id: String
    public let creationTimestamp: Int

    public init(id: String, creationTimestamp: Int) {
        self.id = id
        self.creationTimestamp = creationTimestamp
    }
}

public struct GeneratedPasswordUiModel: Sendable, Identifiable {
    public let id: String
    public let relativeCreationDate: String
    public let state: State

    public enum State: Sendable {
        case masked
        case unmasked(String)
        /// Should never happen in practice where the value of password is not found for a given password ID
        case failedToUnmask
    }

    public init(id: String, relativeCreationDate: String, state: State) {
        self.id = id
        self.relativeCreationDate = relativeCreationDate
        self.state = state
    }
}
