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
    let titleColor: Color
    let font: Font
    let fontWeight: Font.Weight
    let backgroundColor: Color
    let height: CGFloat
    let maxWidth: CGFloat?
    let horizontalPadding: CGFloat?
    let action: () -> Void

    public init(title: String,
                titleColor: Color,
                font: Font = .callout,
                fontWeight: Font.Weight = .regular,
                backgroundColor: Color,
                height: CGFloat = 40,
                maxWidth: CGFloat? = .infinity,
                horizontalPadding: CGFloat? = DesignConstant.sectionPadding,
                action: (() -> Void)? = nil) {
        self.title = title
        self.titleColor = titleColor
        self.font = font
        self.fontWeight = fontWeight
        self.backgroundColor = backgroundColor
        self.height = height
        self.maxWidth = maxWidth
        self.horizontalPadding = horizontalPadding
        self.action = action ?? {}
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                text
                    .frame(maxWidth: maxWidth, maxHeight: .infinity)
            }
            .tint(backgroundColor)
            .buttonStyle(.glassProminent)
            .frame(height: height)
        } else {
            Button(action: action) {
                text
                    .frame(height: height)
                    .frame(maxWidth: maxWidth)
                    .background(backgroundColor, in: .capsule)
            }
        }
    }
}

private extension CapsuleTextButton {
    var text: some View {
        Text(title)
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(titleColor)
            .padding(.horizontal, horizontalPadding)
    }
}

public struct DisablableCapsuleTextButton: View {
    let title: String
    let titleColor: Color
    let disableTitleColor: Color
    let backgroundColor: Color
    let disableBackgroundColor: Color
    let disabled: Bool
    let height: CGFloat
    let maxWidth: CGFloat?
    let action: () -> Void

    public init(title: String,
                titleColor: Color,
                disableTitleColor: Color,
                backgroundColor: Color,
                disableBackgroundColor: Color,
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
        if #available(iOS 26.0, *) {
            Button(action: action) {
                text
                    .frame(maxWidth: maxWidth, maxHeight: .infinity)
            }
            .tint(disabled ? disableBackgroundColor : backgroundColor)
            .buttonStyle(.glassProminent)
            .frame(height: height)
            .disabled(disabled)
            .animation(.default, value: disabled)
        } else {
            Button(action: action) {
                text
                    .padding(.horizontal, 16)
                    .frame(height: height)
                    .frame(maxWidth: maxWidth)
                    .background(disabled ? disableBackgroundColor : backgroundColor)
                    .clipShape(.capsule)
            }
            .disabled(disabled)
            .animation(.default, value: disabled)
        }
    }
}

private extension DisablableCapsuleTextButton {
    var text: some View {
        Text(title)
            .font(.callout)
            .foregroundStyle(disabled ? disableTitleColor : titleColor)
    }
}

/// A capsule button with a text as title
public struct CapsuleTextBorderedButton: View {
    let title: String
    let titleColor: Color
    let font: Font
    let borderColor: Color
    let borderWidth: CGFloat
    let height: CGFloat
    let maxWidth: CGFloat?
    let action: (() -> Void)?

    public init(title: String,
                titleColor: Color,
                font: Font = .callout,
                borderColor: Color,
                borderWidth: CGFloat = 1,
                height: CGFloat = 40,
                maxWidth: CGFloat? = .infinity,
                action: (() -> Void)? = nil) {
        self.title = title
        self.titleColor = titleColor
        self.font = font
        self.borderColor = borderColor
        self.height = height
        self.maxWidth = maxWidth
        self.action = action
        self.borderWidth = borderWidth
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

private extension CapsuleTextBorderedButton {
    var realBody: some View {
        Text(title)
            .font(font)
            .foregroundStyle(titleColor)
            .frame(height: height)
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, 16)
            .background(.clear)
            .clipShape(Capsule())
            .overlay(Capsule()
                .stroke(borderColor, lineWidth: borderWidth))
    }
}
