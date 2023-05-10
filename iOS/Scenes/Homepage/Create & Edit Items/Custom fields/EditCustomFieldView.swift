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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct EditCustomFieldView: View {
    @FocusState private var focusedField: Dummy?
    @State private var isRemoved = false
    let contentType: ItemContentType
    @Binding var customField: CustomField

    var onEditTitle: () -> Void
    var onRemove: () -> Void

    private enum Dummy { case dummy }

    var body: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: customField.type.icon)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text(customField.title)
                    .sectionTitleText()

                // Remove TextField from view's hierachy before removing the custom field
                // otherwise app crashes because of index of range error.
                // Looks like a SwiftUI bug
                // https://stackoverflow.com/a/67436121
                if isRemoved {
                    Text("Dummy text")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(0)
                } else {
                    switch customField.type {
                    case .text, .totp:
                        TextField("", text: $customField.content)
                            .foregroundColor(Color(uiColor: PassColor.textNorm))

                    case .hidden:
                        SensitiveTextField(text: $customField.content,
                                           placeholder: "",
                                           focusedField: $focusedField,
                                           field: .dummy)
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
                    }
                }
            }
            .animation(.default, value: isRemoved)

            Menu(content: {
                Button(action: onEditTitle) {
                    Label(title: { Text("Edit title") },
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
                             backgroundColor: contentType.normMinor1Color)
            })
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
    }
}
