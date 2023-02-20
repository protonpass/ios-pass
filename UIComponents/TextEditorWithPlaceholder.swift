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

public struct TextEditorWithPlaceholder: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    let submitLabel: SubmitLabel

    public init(text: Binding<String>,
                isFocused: FocusState<Bool>.Binding,
                placeholder: String,
                submitLabel: SubmitLabel = .return) {
        self._text = text
        self.isFocused = isFocused
        self.placeholder = placeholder
        self.submitLabel = submitLabel
    }

    public var body: some View {
        if #available(iOS 16.0, *) {
            TextField(placeholder, text: $text, axis: .vertical)
                .focused(isFocused)
                .scrollContentBackground(.hidden)
                .submitLabel(submitLabel)
        } else {
            ZStack {
                if text.isEmpty {
                    TextField(placeholder, text: .constant(""))
                }

                TextEditor(text: $text)
                    .focused(isFocused)
                    .submitLabel(submitLabel)
            }
            .animation(.default, value: text.isEmpty)
        }
    }
}
