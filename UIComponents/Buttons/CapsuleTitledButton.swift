//
// CapsuleTitledButton.swift
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
public struct CapsuleTitledButton: View {
    let icon: UIImage
    let title: String
    let color: UIColor
    let height: CGFloat
    let action: () -> Void

    public init(icon: UIImage,
                title: String,
                color: UIColor,
                height: CGFloat = 40,
                action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.height = height
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Color(uiColor: color.withAlphaComponent(0.4))
                    .clipShape(Capsule())
                // Can not use `Label` here because SwiftUI will not render title
                // when in navigation bar context
                HStack {
                    Image(uiImage: icon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .padding(.vertical, height / 3)
                    Text(title)
                        .font(.callout)
                        .fontWeight(.light)
                }
                .padding(.horizontal)
                .foregroundColor(Color(uiColor: color))
                .frame(maxWidth: .infinity)
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
        }
    }
}
