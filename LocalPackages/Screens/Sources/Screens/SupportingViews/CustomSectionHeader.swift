//
// CustomSectionHeader.swift
// Proton Pass - Created on 04/03/2025.
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

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

public struct CustomSectionHeader: View {
    let title: TextContent
    let collapsed: Bool
    let editable: Bool
    let onToggle: () -> Void
    let onEditTitle: () -> Void
    let onRemove: () -> Void

    public init(title: TextContent,
                collapsed: Bool,
                editable: Bool,
                onToggle: @escaping () -> Void,
                onEditTitle: @escaping () -> Void,
                onRemove: @escaping () -> Void) {
        self.title = title
        self.collapsed = collapsed
        self.editable = editable
        self.onToggle = onToggle
        self.onEditTitle = onEditTitle
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(alignment: .center) {
            Label(title: { Text(title) },
                  icon: {
                      Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                          .resizable()
                          .scaledToFit()
                          .frame(width: 12)
                  })
                  .foregroundStyle(PassColor.textWeak.toColor)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.top, DesignConstant.sectionPadding)
                  .buttonEmbeded(action: onToggle)

            Spacer()

            if editable {
                Menu(content: {
                    Label(title: { Text("Edit section's title", bundle: .module) },
                          icon: { Image(uiImage: IconProvider.pencil) })
                        .buttonEmbeded(action: onEditTitle)

                    Label(title: { Text("Remove section", bundle: .module) },
                          icon: { Image(uiImage: IconProvider.crossCircle) })
                        .buttonEmbeded(action: onRemove)
                }, label: {
                    IconProvider.threeDotsVertical
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .padding(.top, DesignConstant.sectionPadding)
                })
            }
        }
    }
}
