//
// CustomSection.swift
// Proton Pass - Created on 23/05/2024.
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

public struct CustomSection: Equatable, Hashable, Sendable, Identifiable {
    public let id: String
    public var title: String
    public var isCollapsed: Bool
    public var content: [CustomField]

    public init(id: String = UUID().uuidString,
                title: String,
                isCollapsed: Bool = false,
                content: [CustomField]) {
        self.id = id
        self.title = title
        self.isCollapsed = isCollapsed
        self.content = content
    }

    init(from extraSection: ProtonPassItemV1_CustomSection) {
        id = UUID().uuidString
        title = extraSection.sectionName
        isCollapsed = false
        content = extraSection.sectionFields.map { .init(from: $0) }
    }
}
