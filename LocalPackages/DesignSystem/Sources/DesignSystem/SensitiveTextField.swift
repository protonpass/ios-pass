//
// SensitiveTextField.swift
// Proton Pass - Created on 02/05/2023.
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

import SwiftUI

/// TextField for sensitive content like password or TOTP URI
/// When not focused, content is covered by a string of "•"
public struct SensitiveTextField<Field: Hashable>: View {
    @Binding var text: String
    let placeholder: String
    let focusedField: FocusState<Field>.Binding
    let field: Field
    let font: UIFont
    let fontWeight: UIFont.Weight
    let onSubmit: (() -> Void)?

    private var isFocused: Bool { focusedField.wrappedValue == field }
    private var shouldShowTextEditor: Bool { isFocused || text.isEmpty }

    public init(text: Binding<String>,
                placeholder: String,
                focusedField: FocusState<Field>.Binding,
                field: Field,
                font: UIFont = .body,
                fontWeight: UIFont.Weight = .regular,
                onSubmit: (() -> Void)? = nil) {
        _text = text
        self.placeholder = placeholder
        self.focusedField = focusedField
        self.field = field
        self.font = font
        self.fontWeight = fontWeight
        self.onSubmit = onSubmit
    }

    public var body: some View {
        ZStack {
            TextEditorWithPlaceholder(text: $text,
                                      focusedField: focusedField,
                                      field: field,
                                      placeholder: placeholder,
                                      font: font,
                                      fontWeight: fontWeight,
                                      onSubmit: onSubmit)
                .frame(maxHeight: shouldShowTextEditor ? .infinity : 0)
                .opacity(shouldShowTextEditor ? 1 : 0)

            if !text.isEmpty {
                Button(action: {
                    focusedField.wrappedValue = field
                }, label: {
                    Text(String(repeating: "•", count: min(20, text.count)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                })
                .opacity(isFocused ? 0 : 1)
                .buttonStyle(.plain)
            }
        }
        .animation(.default, value: shouldShowTextEditor)
    }
}
