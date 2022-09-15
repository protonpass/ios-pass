//
// UserInputContainerView.swift
// Proton Pass - Created on 08/08/2022.
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

import ProtonCore_UIFoundations
import SwiftUI

public struct UserInputContainerView<Content: View>: View {
    let title: String?
    let isFocused: Bool
    var isEditable: Bool
    let content: () -> Content

    public init(title: String?,
                isFocused: Bool,
                isEditable: Bool = true,
                @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.isFocused = isFocused
        self.isEditable = isEditable
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            content()
            .padding(10)
            .background(Color(ColorProvider.BackgroundSecondary).opacity(isEditable ? 1 : 0.25))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color(ColorProvider.BrandNorm) : Color.clear, lineWidth: 1)
            )
            .accentColor(Color(ColorProvider.BrandNorm))
        }
    }
}
