//
// ToolbarButton.swift
// Proton Pass - Created on 22/05/2025.
// Copyright (c) 2025 Proton Technologies AG
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

public struct ToolbarButton: View {
    let title: LocalizedStringKey
    let titleBundle: Bundle
    let image: UIImage
    let action: () -> Void

    public init(_ title: LocalizedStringKey,
                titleBundle: Bundle,
                image: UIImage,
                action: @escaping () -> Void) {
        self.title = title
        self.titleBundle = titleBundle
        self.image = image
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            // Use HStack instead of Label because Label's text is not rendered in toolbar
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 18, height: 18)
                Text(title, bundle: titleBundle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
