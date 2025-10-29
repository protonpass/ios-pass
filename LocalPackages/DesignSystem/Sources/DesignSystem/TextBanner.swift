//
// TextBanner.swift
// Proton Pass - Created on 05/03/2024.
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

public struct TextBanner: View {
    let text: LocalizedStringKey
    let foregroundColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat

    public init(_ text: LocalizedStringKey,
                foregroundColor: Color = PassColor.textNorm,
                backgroundColor: Color = PassColor.interactionNormMinor1,
                cornerRadius: CGFloat = 16) {
        self.text = text
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Text(text)
            .padding()
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .multilineTextAlignment(.leading)
    }
}
