//
// ColoredRoundedButton.swift
// Proton Pass - Created on 06/12/2022.
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

import SwiftUI

public struct ColoredRoundedButton: View {
    let title: String
    let titleColor: Color
    let backgroundColor: Color
    let action: () -> Void

    public init(title: String,
                titleColor: Color = .white,
                backgroundColor: Color = Color(uiColor: PassColor.interactionNorm),
                action: @escaping () -> Void) {
        self.title = title
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(12)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
