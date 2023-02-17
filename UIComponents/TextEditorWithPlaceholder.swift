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
    @State private var isShowingPlaceholder: Bool
    var isFocused: FocusState<Bool>.Binding
    @Binding var text: String
    let placeholder: String

    public init(text: Binding<String>,
                isFocused: FocusState<Bool>.Binding,
                placeholder: String) {
        self._isShowingPlaceholder = .init(initialValue: text.wrappedValue.isEmpty)
        self._text = text
        self.isFocused = isFocused
        self.placeholder = placeholder
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if #available(iOS 16.0, *) {
                TextEditor(text: $text)
                    .focused(isFocused)
                    .scrollContentBackground(.hidden)
                    .offset(x: -4)
            } else {
                TextEditor(text: $text)
                    .focused(isFocused)
                    .offset(x: -4)
            }

            if isShowingPlaceholder {
                TextField(placeholder, text: .constant("")) { changed in
                    if changed {
                        isShowingPlaceholder = false
                        isFocused.wrappedValue = true
                    }
                }
            }
        }
        .onChange(of: isFocused.wrappedValue) { _ in
            isShowingPlaceholder = text.isEmpty
        }
        .onChange(of: text) { text in
            isShowingPlaceholder = text.isEmpty
        }
    }
}
