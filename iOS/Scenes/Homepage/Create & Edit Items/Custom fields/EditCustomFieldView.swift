//
// EditCustomFieldView.swift
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct EditCustomFieldView<Field: Hashable>: View {
    let focusedField: FocusState<Field?>.Binding
    let field: Field
    @State private var isRemoved = false
    let contentType: ItemContentType
    @Binding var uiModel: CustomFieldUiModel

    var showIcon = true
    var roundedSection = true
    var onEditTitle: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if showIcon {
                ItemDetailSectionIcon(icon: uiModel.customField.type.icon)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(uiModel.customField.title)
                    .sectionTitleText()

                // Remove TextField from view's hierachy before removing the custom field
                // otherwise app crashes because of index of range error.
                // Looks like a SwiftUI bug
                // https://stackoverflow.com/a/67436121
                if isRemoved {
                    Text(verbatim: "Dummy text")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(0)
                } else {
                    let placeholder = uiModel.customField.type.title
                    switch uiModel.customField.type {
                    case .text:
                        TextEditorWithPlaceholder(text: $uiModel.customField.content,
                                                  focusedField: focusedField,
                                                  field: field,
                                                  placeholder: placeholder)

                    case .totp:
                        SensitiveTextField(text: $uiModel.customField.content,
                                           placeholder: placeholder,
                                           focusedField: focusedField,
                                           field: field,
                                           font: .body.monospacedFont(for: uiModel.customField.content))
                            .foregroundStyle(PassColor.textNorm.toColor)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                    case .hidden:
                        SensitiveTextField(text: $uiModel.customField.content,
                                           placeholder: placeholder,
                                           focusedField: focusedField,
                                           field: field)
                            .foregroundStyle(PassColor.textNorm.toColor)
                    }
                }
            }
            .animation(.default, value: isRemoved)

            Menu(content: {
                Button(action: onEditTitle) {
                    Label(title: { Text("Edit name") },
                          icon: { Image(uiImage: IconProvider.pencil) })
                }

                Button(action: {
                    isRemoved.toggle()
                    onRemove()
                }, label: {
                    Label(title: { Text("Remove field") },
                          icon: { Image(uiImage: IconProvider.crossCircle) })
                })
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: contentType.normMajor1Color,
                             backgroundColor: contentType.normMinor1Color,
                             accessibilityLabel: "Custom field menu")
            })
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .if(roundedSection) { view in
            view
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
        }
    }
}
