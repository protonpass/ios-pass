//
// CreateEditItemTitleSection.swift
// Proton Pass - Created on 13/02/2023.
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
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreateEditItemTitleSection<Field: Hashable>: View {
    @Binding var title: String
    let focusedField: FocusState<Field?>.Binding
    let field: Field
    let itemContentType: ItemContentType
    let isEditMode: Bool
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Title")
                    .sectionTitleText()
                TextEditorWithPlaceholder(text: $title,
                                          focusedField: focusedField,
                                          field: field,
                                          placeholder: #localized("Untitled"),
                                          font: .title,
                                          fontWeight: .bold,
                                          onSubmit: onSubmit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $title)
        }
        .padding(DesignConstant.sectionPadding)
        .animation(.default, value: title.isEmpty)
        .roundedEditableSection()
    }
}
