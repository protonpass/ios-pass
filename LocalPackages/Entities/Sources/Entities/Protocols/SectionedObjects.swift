//
// SectionedObjects.swift
// Proton Pass - Created on 30/10/2024.
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

import Foundation

public struct SectionedObjects<T: Sendable & Equatable & Identifiable>: Sendable, Equatable, Identifiable {
    public let id: String
    public let sectionTitle: String
    public let items: [T]

    public init(id: String, sectionTitle: String, items: [T]) {
        self.id = id
        self.sectionTitle = sectionTitle
        self.items = items
    }
}
