//
// ItemDetailTitleView.swift
// Proton Pass - Created on 02/02/2023.
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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

enum ItemDetailTitleIcon {
    case image(UIImage)
    case initials(String)
    case notApplicable
}

struct ItemDetailTitleView: View {
    let title: String
    let icon: ItemDetailTitleIcon
    let iconTintColor: UIColor
    let iconBackgroundColor: UIColor

    init(itemContent: ItemContent) {
        self.title = itemContent.name
        self.iconTintColor = itemContent.type.normMajor1Color
        self.iconBackgroundColor = itemContent.type.normMinor1Color
        switch itemContent.contentData.type {
        case .alias:
            self.icon = .image(IconProvider.alias)
        case .login:
            self.icon = .initials(String(itemContent.name.prefix(2)).uppercased())
        case .note:
            self.icon = .notApplicable
        }
    }

    var body: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ZStack {
                Color(uiColor: iconBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                switch icon {
                case .image(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .foregroundColor(Color(uiColor: iconTintColor))
                case .initials(let initials):
                    Text(initials.uppercased())
                        .fontWeight(.medium)
                        .foregroundColor(Color(uiColor: iconTintColor))
                case .notApplicable:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 60)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .textSelection(.enabled)
                .lineLimit(2)
                .foregroundColor(Color(uiColor: PassColor.textNorm))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
