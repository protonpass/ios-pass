//
// BorderedImageButton.swift
// Proton Pass - Created on 22/11/2022.
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

public struct BorderedImageButton: View {
    let image: UIImage
    let imageTintColor: Color
    let borderColor: Color
    let borderRadius: CGFloat
    let action: () -> Void

    public init(image: UIImage,
                imageTintColor: Color = .primary,
                borderColor: Color = .separatorNorm,
                borderRadius: CGFloat = 8.0,
                action: @escaping () -> Void) {
        self.image = image
        self.imageTintColor = imageTintColor
        self.borderColor = borderColor
        self.borderRadius = borderRadius
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(uiImage: image)
                .resizable()
                .foregroundColor(imageTintColor)
                .padding(13.5)
        }
        .overlay(
            RoundedRectangle(cornerRadius: borderRadius)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}
