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
    public let title: String
    public var content: [CustomField]

    public var id: Int { hashValue }

    public init(title: String, content: [CustomField]) {
        self.title = title
        self.content = content
    }

    init(from extraSection: ProtonPassItemV1_ExtraIdentitySection) {
        title = extraSection.sectionName
        content = extraSection.sectionFields.map { .init(from: $0) }
    }
}

public extension CustomSection {
    init(from extraSection: ProtonPassItemV1_CustomSection) {
        title = extraSection.sectionName
        content = extraSection.sectionFields.map { .init(from: $0) }
    }
}
