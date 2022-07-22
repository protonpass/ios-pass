//
// TitledTextField.swift
// Proton Pass - Created on 16/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_UIFoundations
import SwiftUI

public struct TitledTextField: View {
    @Binding private var text: String
    @State private var isFocused = false
    private let title: String
    private let placeholder: String
    private let isRequired: Bool

    public init(title: String,
                text: Binding<String>,
                placeholder: String = "",
                isRequired: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self.isRequired = isRequired
        self._text = text
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            TextField(placeholder, text: $text) { editingChanged in
                self.isFocused = editingChanged
            }
            .padding(10)
            .background(Color(ColorProvider.BackgroundSecondary))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color(ColorProvider.BrandNorm) : Color.clear, lineWidth: 1)
            )
            .accentColor(Color(ColorProvider.BrandNorm))

            if isRequired {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TitledTextField_Previews: PreviewProvider {
    static var previews: some View {
        TitledTextField(title: "Test title",
                        text: .constant(""))
    }
}
