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

public enum TitledTextFieldContentType {
    case clearText
    case secureEntry(Binding<Bool>, UIToolbar)
}

public struct TitledTextField<TrailingView: View>: View {
    @State private var isFocused = false
    @Binding var text: String
    let title: String
    let placeholder: String
    let isRequired: Bool
    let contentType: TitledTextFieldContentType
    let trailingView: TrailingView

    public init(title: String,
                placeholder: String,
                text: Binding<String>,
                contentType: TitledTextFieldContentType,
                isRequired: Bool,
                @ViewBuilder trailingView: (() -> TrailingView)) {
        self.title = title
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.contentType = contentType
        self._text = text
        self.trailingView = trailingView()
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            HStack {
                content
                trailingView
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

    @ViewBuilder
    private var content: some View {
        switch contentType {
        case .clearText:
            TextField(placeholder, text: $text) { editingChanged in
                self.isFocused = editingChanged
            }
        case let .secureEntry(isSecureTextEntry, toolbar):
            TextFieldWithToolbar(text: $text,
                                 isSecureTextEntry: isSecureTextEntry,
                                 placeholder: placeholder,
                                 toolbar: toolbar) { editingChanged in
                self.isFocused = editingChanged
            }
        }
    }
}
