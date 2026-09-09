//
// ItemDetailSectionIcon.swift
// Proton Pass - Created on 02/08/2024.
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

import DesignSystem
import SwiftUI

public struct ItemDetailSectionIcon: View {
    let icon: Image
    let color: Color
    let width: CGFloat

    public init(icon: Image,
                color: Color = PassColor.textWeak,
                width: CGFloat = 20) {
        self.icon = icon
        self.color = color
        self.width = width
    }

    public var body: some View {
        icon
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
    }
}
