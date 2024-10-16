//
// IdentityDetailData.swift
// Proton Pass - Created on 09/10/2024.
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

struct IdentityDetailSection: Identifiable {
    let title: String
    let rows: [IdentityDetailRow]
    let customFields: [CustomFieldUiModel]

    var id: String {
        title
    }

    init(title: String, rows: [IdentityDetailRow], customFields: [CustomFieldUiModel]) {
        self.title = title
        self.rows = rows.filter { $0.value?.isEmpty == false }
        self.customFields = customFields
    }

    var isEmpty: Bool {
        rows.isEmpty && customFields.isEmpty
    }
}

struct IdentityDetailRow: Identifiable, Equatable {
    let title: String
    let value: String?
    var isSocialSecurityNumber = false

    var id: String {
        title + (value ?? "")
    }
}
