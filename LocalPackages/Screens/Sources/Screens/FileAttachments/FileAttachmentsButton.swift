//
// FileAttachmentsButton.swift
// Proton Pass - Created on 19/11/2024.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct FileAttachmentsButton: View {
    let style: Style
    let iconColor: UIColor
    let backgroundColor: UIColor
    let onSelect: (FileAttachmentMethod) -> Void

    public enum Style {
        case circle, capsule
    }

    public init(style: Style,
                iconColor: UIColor,
                backgroundColor: UIColor,
                onSelect: @escaping (FileAttachmentMethod) -> Void) {
        self.style = style
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.onSelect = onSelect
    }

    public var body: some View {
        Menu(content: {
            ForEach(FileAttachmentMethod.allCases, id: \.self) { method in
                Label(title: {
                    Text(method.title)
                }, icon: {
                    Image(uiImage: method.icon)
                        .resizable()
                })
                .buttonEmbeded {
                    onSelect(method)
                }
            }
        }, label: {
            switch style {
            case .circle:
                CircleButton(icon: IconProvider.paperClipVertical,
                             iconColor: iconColor,
                             backgroundColor: backgroundColor)

            case .capsule:
                CapsuleTextButton(title: #localized("Attach a file"),
                                  titleColor: iconColor,
                                  backgroundColor: backgroundColor,
                                  height: 48)
            }
        })
    }
}
