//
// ParenthesizedText.swift
// Proton Pass - Created on 14/04/2026.
// Copyright (c) 2026 Proton Technologies AG
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

public struct ParenthesizedText: View {
    let content: String
    let contentColor: Color
    let leftSymbol: String
    let rightSymbol: String
    let symbolColor: Color

    public init(content: String,
                contentColor: Color,
                leftSymbol: String = "(",
                rightSymbol: String = ")",
                symbolColor: Color = PassColor.textNorm) {
        self.content = content
        self.contentColor = contentColor
        self.leftSymbol = leftSymbol
        self.rightSymbol = rightSymbol
        self.symbolColor = symbolColor
    }

    public var body: some View {
        Text(attributedString)
    }
}

private extension ParenthesizedText {
    var attributedString: AttributedString {
        var leftSymbolString = AttributedString(leftSymbol)
        leftSymbolString.foregroundColor = symbolColor

        var rightSymbolString = AttributedString(rightSymbol)
        rightSymbolString.foregroundColor = symbolColor

        var contentString = AttributedString(content)
        contentString.foregroundColor = contentColor

        return leftSymbolString + contentString + rightSymbolString
    }
}
