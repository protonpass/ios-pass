//
// GradientRoundedButton.swift
// Proton Pass - Created on 20/10/2023.
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

public struct GradientRoundedButton: View {
    let title: LocalizedStringKey
    let titleColor: Color
    let leadingBackgroundColor: Color
    let endingBackgroundColor: Color
    let action: () -> Void

    public init(title: LocalizedStringKey,
                titleColor: Color = .white,
                leadingBackgroundColor: Color,
                endingBackgroundColor: Color,
                action: @escaping () -> Void) {
        self.title = title
        self.titleColor = titleColor
        self.leadingBackgroundColor = leadingBackgroundColor
        self.endingBackgroundColor = endingBackgroundColor
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(12)
        }
        .background(LinearGradient(colors: [
                leadingBackgroundColor,
                endingBackgroundColor
            ], // swiftlint:disable:this literal_expression_end_indentation
            startPoint: .leading,
            endPoint: .trailing))
        .clipShape(Capsule())
    }
}
