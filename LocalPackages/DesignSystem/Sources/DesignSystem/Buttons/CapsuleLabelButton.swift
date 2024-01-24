//
// CapsuleLabelButton.swift
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
public struct CapsuleLabelButton: View {
    let icon: UIImage
    let title: String
    let titleColor: UIColor
    let backgroundColor: UIColor
    let height: CGFloat
    let maxWidth: CGFloat?
    let action: () -> Void
    let isDisabled: Bool
    let leadingIcon: Bool

    public init(icon: UIImage,
                title: String,
                titleColor: UIColor,
                backgroundColor: UIColor,
                height: CGFloat = 40,
                maxWidth: CGFloat? = .infinity,
                isDisabled: Bool = false,
                leadingIcon: Bool = false,
                action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.height = height
        self.maxWidth = maxWidth
        self.action = action
        self.isDisabled = isDisabled
        self.leadingIcon = leadingIcon
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if leadingIcon {
                    ZStack(alignment: .leading) {
                        iconView
                        HStack {
                            Spacer()
                            titleView
                            Spacer()
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        iconView
                        titleView
                    }
                }
            }
            .padding(.horizontal)
            .foregroundColor(titleColor.toColor)
            .frame(height: height)
            .frame(maxWidth: maxWidth)
            .background(backgroundColor.toColor.opacity(isDisabled ? 0.4 : 1.0))
            .clipShape(Capsule())
            .contentShape(Rectangle())
        }
        .disabled(isDisabled)
    }
}

private extension CapsuleLabelButton {
    var iconView: some View {
        Image(uiImage: icon)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(maxHeight: height / 2.2)
    }

    var titleView: some View {
        Text(title)
            .font(.callout)
    }
}
