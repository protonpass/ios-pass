//
// SwiftUIImage.swift
// Proton Pass - Created on 27/06/2024.
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

public struct SwiftUIImage: View {
    let image: UIImage
    let width: CGFloat
    let height: CGFloat
    let defaultWidthHeight: CGFloat = 20
    let contentMode: ContentMode
    let tintColor: Color

    public init(image: UIImage,
                width: CGFloat? = nil,
                height: CGFloat? = nil,
                contentMode: ContentMode = .fit,
                tintColor: Color = PassColor.textNorm) {
        self.image = image

        if let width, let height {
            self.width = width
            self.height = height
        } else if let width, height == nil {
            self.width = width
            self.height = width
        } else if let height, width == nil {
            self.width = height
            self.height = height
        } else {
            self.width = defaultWidthHeight
            self.height = defaultWidthHeight
        }

        self.contentMode = contentMode
        self.tintColor = tintColor
    }

    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(width: width, height: height)
            .foregroundStyle(tintColor)
            .accessibilityIdentifier("SwiftUIImage")
    }
}
