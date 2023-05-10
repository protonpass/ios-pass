//
// CustomFieldSections.swift
// Proton Pass - Created on 10/05/2023.
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

import Client
import SwiftUI

struct CustomFieldSections: View {
    let contentType: ItemContentType
    @Binding var customFields: [CustomField]
    let onAddMore: () -> Void
    let onEditTitle: (CustomField) -> Void

    var body: some View {
        ForEach($customFields) { $field in
            EditCustomFieldView(contentType: contentType,
                                customField: $field,
                                onEditTitle: { onEditTitle(field) },
                                onRemove: { customFields.removeAll(where: { $0.id == field.id }) })
        }

        Button(action: onAddMore) {
            Label(title: {
                Text("Add more")
                    .font(.callout)
                    .fontWeight(.medium)
            }, icon: {
                Image(systemName: "plus")
            })
            .foregroundColor(Color(uiColor: contentType.normMajor2Color))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, kItemDetailSectionPadding)
    }
}
