//
// CapsuleTextButton.swift
// Proton Pass - Created on 16/02/2023.
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

/// A capsule button with a text as title
public struct CapsuleTextButton: View {
    let title: String
    let titleColor: UIColor
    let font: Font
    let backgroundColor: UIColor
    let height: CGFloat
    let maxWidth: CGFloat?
    let action: (() -> Void)?

    public init(title: String,
                titleColor: UIColor,
                font: Font = .callout,
                backgroundColor: UIColor,
                height: CGFloat = 40,
                maxWidth: CGFloat? = .infinity,
                action: (() -> Void)? = nil) {
        self.title = title
        self.titleColor = titleColor
        self.font = font
        self.backgroundColor = backgroundColor
        self.height = height
        self.maxWidth = maxWidth
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
}

private extension CapsuleTextButton {
    var realBody: some View {
        Text(title)
            .font(font)
            .foregroundStyle(titleColor.toColor)
            .frame(height: height)
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, 16)
            .background(backgroundColor.toColor)
            .clipShape(Capsule())
    }
}

public struct DisablableCapsuleTextButton: View {
    let title: String
    let titleColor: UIColor
    let disableTitleColor: UIColor
    let backgroundColor: UIColor
    let disableBackgroundColor: UIColor
    let disabled: Bool
    let height: CGFloat
    let maxWidth: CGFloat?
    let action: () -> Void

    public init(title: String,
                titleColor: UIColor,
                disableTitleColor: UIColor,
                backgroundColor: UIColor,
                disableBackgroundColor: UIColor,
                disabled: Bool,
                height: CGFloat = 40,
                maxWidth: CGFloat? = .infinity,
                action: @escaping () -> Void) {
        self.title = title
        self.titleColor = titleColor
        self.disableTitleColor = disableTitleColor
        self.backgroundColor = backgroundColor
        self.disableBackgroundColor = disableBackgroundColor
        self.disabled = disabled
        self.height = height
        self.maxWidth = maxWidth
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .foregroundStyle((disabled ? disableTitleColor : titleColor).toColor)
                .frame(height: height)
                .frame(maxWidth: maxWidth)
                .padding(.horizontal, 16)
                .background((disabled ? disableBackgroundColor : backgroundColor).toColor)
                .clipShape(Capsule())
        }
        .disabled(disabled)
        .animation(.default, value: disabled)
    }
}
