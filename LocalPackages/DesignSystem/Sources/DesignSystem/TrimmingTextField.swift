//
// TrimmingTextField.swift
// Proton Pass - Created on 03/09/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import SwiftUI

public struct TrimmingTextField: View {
    private let placeholder: LocalizedStringKey
    private let trimmedCharacterSet: CharacterSet
    @Binding private var text: String

    public init(_ placeholder: LocalizedStringKey,
                text: Binding<String>,
                trimmedCharacterSet: CharacterSet = .whitespacesAndNewlines) {
        self.placeholder = placeholder
        _text = text
        self.trimmedCharacterSet = trimmedCharacterSet
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            .onChange(of: text) { newValue in
                text = newValue.trimmingCharacters(in: trimmedCharacterSet)
            }
    }
}
