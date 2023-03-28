//
// CapsuleLabelButton.swift
// Proton Pass - Created on 03/02/2023.
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

/// A capsule button with an icon on the left & title on the right.
public struct CapsuleLabelButton: View {
    let icon: UIImage
    let title: String
    let backgroundColor: UIColor
    let disabled: Bool
    let height: CGFloat
    let action: () -> Void

    public init(icon: UIImage,
                title: String,
                backgroundColor: UIColor,
                disabled: Bool,
                height: CGFloat = 40,
                action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.backgroundColor = backgroundColor
        self.disabled = disabled
        self.height = height
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                Image(uiImage: icon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(maxHeight: height / 2)
                Text(title)
            }
            .padding(.horizontal)
            .foregroundColor(Color(uiColor: .textNorm))
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .foregroundColor(disabled ? .textDisabled : .textNorm)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: backgroundColor).opacity(disabled ? 0.08 : 1))
            .clipShape(Capsule())
        }
    }
}
