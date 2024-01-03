//
// VaultRow.swift
// Proton Pass - Created on 29/03/2023.
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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct VaultRow<Thumbnail: View>: View {
    let thumbnail: () -> Thumbnail
    let title: String
    let itemCount: Int
    let isShared: Bool
    let isSelected: Bool
    var showBadge = false
    var maxWidth: CGFloat? = .infinity
    var height: CGFloat = 70

    var body: some View {
        HStack(spacing: 16) {
            thumbnail()

            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))

                if itemCount == 0 {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text("\(itemCount) item(s)")
                        .font(.callout)
                        .foregroundColor(Color(uiColor: PassColor.textWeak))
                }
            }

            if maxWidth != nil {
                Spacer()
            }

            if isShared {
                HStack(spacing: 0) {
                    Image(uiImage: IconProvider.users)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(PassColor.textWeak.toColor)
                        .frame(maxHeight: 20)
                    if showBadge {
                        Image(uiImage: IconProvider.exclamationCircleFilled)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(PassColor.signalDanger.toColor)
                            .frame(maxHeight: 16)
                            .offset(y: -10)
                    }
                }
            }

            if isSelected {
                Image(uiImage: IconProvider.checkmark)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(uiColor: PassColor.interactionNorm))
                    .frame(maxHeight: 20)
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(height: height)
        .contentShape(Rectangle())
    }
}
