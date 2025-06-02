//
// EditCustomFieldSections.swift
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

import DesignSystem
import Entities
import Foundation
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct EditCustomFieldSections<Field: CustomFieldTypes>: View {
    let focusedField: FocusState<Field?>.Binding
    let focusedCustomField: CustomField?
    let contentType: ItemContentType
    @Binding var fields: [CustomField]
    let canAddMore: Bool
    let onAddMore: () -> Void
    let onEditTitle: (CustomField) -> Void
    let onUpgrade: () -> Void

    var body: some View {
        ForEach($fields) { $field in
            EditCustomFieldView(focusedField: focusedField,
                                field: .custom(field),
                                contentType: contentType,
                                value: $field,
                                onEditTitle: { onEditTitle(field) },
                                onRemove: { fields.remove(field) })
        }
        .onChange(of: focusedCustomField) { newValue in
            focusedField.wrappedValue = .custom(newValue)
        }

        if canAddMore {
            addMoreButton
        } else {
            upgradeButton
        }
    }

    private var addMoreButton: some View {
        HStack {
            CapsuleLabelButton(icon: UIImage(systemName: "plus") ?? .init(),
                               title: #localized("Add more"),
                               titleColor: contentType.normMajor2Color,
                               backgroundColor: contentType.normMinor1Color,
                               maxWidth: nil,
                               action: onAddMore)
            Spacer()
        }
    }

    private var upgradeButton: some View {
        Button(action: onUpgrade) {
            Label(title: {
                Text("Upgrade to add custom fields")
                    .font(.callout)
                    .fontWeight(.medium)
            }, icon: {
                Image(uiImage: IconProvider.arrowOutSquare)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 16)
            })
            .foregroundStyle(contentType.normMajor2Color.toColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignConstant.sectionPadding)
    }
}
