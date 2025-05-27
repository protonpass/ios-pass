//
// TextEditorWithPlaceholder.swift
// Proton Pass - Created on 09/02/2023.
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

/// While this view expands the height as its content grows, scroll position doesn't move accordingly
/// which results in new lines hidden being behind the keyboard.
/// Prefer using `EditableTextView` (`UITextView`'s wrapper)
/// when dealing with potential multilines text editor (e.g content of a note item)
public struct TextEditorWithPlaceholder<Field: Hashable>: View {
    @Binding var text: String
    let font: UIFont
    let fontWeight: UIFont.Weight
    let focusedField: FocusState<Field>.Binding
    let field: Field
    let placeholder: String
    let minHeight: CGFloat?
    let onSubmit: (() -> Void)?

    public init(text: Binding<String>,
                focusedField: FocusState<Field>.Binding,
                field: Field,
                placeholder: String,
                minHeight: CGFloat? = nil,
                font: UIFont = .body,
                fontWeight: UIFont.Weight = .regular,
                onSubmit: (() -> Void)? = nil) {
        _text = text
        self.font = font
        self.fontWeight = fontWeight
        self.focusedField = focusedField
        self.field = field
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.onSubmit = onSubmit
    }

    public var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .focused(focusedField, equals: field)
            .scrollContentBackground(.hidden)
            .submitLabel(onSubmit != nil ? .next : .return)
            .foregroundStyle(PassColor.textNorm.toColor)
            .font(Font(font.weight(fontWeight)))
            .frame(minHeight: minHeight, alignment: .topLeading)
            .onChange(of: text) { text in
                if let onSubmit, text.contains("\n") {
                    self.text = text.replacingOccurrences(of: "\n", with: "")
                    onSubmit()
                }
            }
    }
}
