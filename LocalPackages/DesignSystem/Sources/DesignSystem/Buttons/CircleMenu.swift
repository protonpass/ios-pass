//
// CircleMenu.swift
// Proton Pass - Created on 04/08/2026.
// Copyright (c) 2026 Proton Technologies AG
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

/// Renders `Menu` with liquid glass effect. Do NOT use inside a toolbar
/// because toolbar renders extra padding. Prefer a normal `Menu` with `CircleButton` as label for toolbar.
public struct CircleMenu<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    private let icon: Image
    private let iconColor: Color
    private let iconDisabledColor: Color
    private let backgroundColor: Color
    private let backgroundDisabledColor: Color
    private let type: CircleButtonType
    private let accessibilityLabel: LocalizedStringKey?
    @ViewBuilder private let content: () -> Content

    public init(icon: Image,
                iconColor: Color,
                iconDisabledColor: Color = PassColor.textDisabled,
                backgroundColor: Color,
                backgroundDisabledColor: Color = PassColor.backgroundWeak,
                accessibilityLabel: LocalizedStringKey? = nil,
                type: CircleButtonType = .regular,
                @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.iconDisabledColor = iconDisabledColor
        self.backgroundColor = backgroundColor
        self.backgroundDisabledColor = backgroundDisabledColor
        self.type = type
        self.accessibilityLabel = accessibilityLabel
        self.content = content
    }

    public var body: some View {
        Menu(content: content, label: { label })
            .if(accessibilityLabel) { view, label in
                view.accessibilityLabel(label)
            }
    }
}

private extension CircleMenu {
    @ViewBuilder
    var label: some View {
        if #available(iOS 26.0, *) {
            iconView
                .frame(width: type.width, height: type.width)
                .glassEffect(.regular.tint(isEnabled ? backgroundColor : backgroundDisabledColor),
                             in: .circle)
        } else {
            CircleButton(icon: icon,
                         iconColor: iconColor,
                         iconDisabledColor: iconDisabledColor,
                         backgroundColor: backgroundColor,
                         backgroundDisabledColor: backgroundDisabledColor,
                         type: type)
        }
    }

    var iconView: some View {
        CircleButtonIcon(icon: icon,
                         color: iconColor,
                         disabledColor: iconDisabledColor,
                         width: type.iconWidth)
    }
}
