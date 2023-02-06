//
// CapsuleButton.swift
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

/// A capsule button with an icon inside.
public struct CapsuleButton: View {
    let icon: UIImage
    let color: UIColor
    let height: CGFloat
    let action: () -> Void

    public init(icon: UIImage,
                color: UIColor,
                height: CGFloat = 40,
                action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.height = height
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Color(uiColor: color.withAlphaComponent(0.2))
                    .clipShape(Capsule())
                Image(uiImage: icon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(Color(uiColor: color))
                    .padding(.vertical, height / 3)
                    .padding(.horizontal)
            }
            .frame(height: height)
        }
    }
}
