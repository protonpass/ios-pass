//
// NoteEditSection.swift
// Proton Pass - Created on 10/02/2023.
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
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct NoteEditSection<Field: Hashable>: View {
    @Binding var note: String
    let focusedField: FocusState<Field?>.Binding
    let field: Field

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.note)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Note")
                    .editableSectionTitleText(for: note)

                TextEditorWithPlaceholder(text: $note,
                                          focusedField: focusedField,
                                          field: field,
                                          placeholder: #localized("Add note"))
                    .frame(maxWidth: .infinity, maxHeight: 350, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $note)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
        .animation(.default, value: note.isEmpty)
    }
}
