//
// CircleButton.swift
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

/// A cirle button with an icon inside.
public struct CircleButton: View {
    let icon: UIImage
    let iconColor: UIColor
    let backgroundColor: UIColor
    let height: CGFloat
    let action: (() -> Void)?

    public init(icon: UIImage,
                iconColor: UIColor,
                backgroundColor: UIColor,
                height: CGFloat = 40,
                action: (() -> Void)? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.height = height
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                realBody
            }
        } else {
            realBody
        }
    }

    private var realBody: some View {
        ZStack {
            Color(uiColor: backgroundColor)
                .clipShape(Circle())
            Image(uiImage: icon)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(Color(uiColor: iconColor))
                .padding(.vertical, height / 4)
        }
        .frame(width: height, height: height)
    }
}
