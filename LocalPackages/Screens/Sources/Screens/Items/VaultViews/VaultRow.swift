//
// VaultRow.swift
// Proton Pass - Created on 06/08/2024.
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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct VaultRow<Thumbnail: View>: View {
    private let thumbnail: () -> Thumbnail
    private let title: String
    private let itemCount: Int
    private let isShared: Bool
    private let isSelected: Bool
    private let showBadge: Bool
    private let maxWidth: CGFloat?
    private let height: CGFloat

    public init(@ViewBuilder thumbnail: @escaping () -> Thumbnail,
                title: String,
                itemCount: Int,
                isShared: Bool,
                isSelected: Bool,
                showBadge: Bool = false,
                maxWidth: CGFloat? = .infinity,
                height: CGFloat = 70) {
        self.thumbnail = thumbnail
        self.title = title
        self.itemCount = itemCount
        self.isShared = isShared
        self.isSelected = isSelected
        self.showBadge = showBadge
        self.maxWidth = maxWidth
        self.height = height
    }

    public var body: some View {
        HStack(spacing: 16) {
            thumbnail()

            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(PassColor.textNorm.toColor)

                if itemCount == 0 {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text("\(itemCount) item(s)")
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak.toColor)
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
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxHeight: 20)
                    if showBadge {
                        Image(uiImage: IconProvider.exclamationCircleFilled)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(PassColor.signalDanger.toColor)
                            .frame(maxHeight: 16)
                            .offset(y: -10)
                    }
                }
            }

            if isSelected {
                Image(uiImage: IconProvider.checkmark)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(PassColor.interactionNorm.toColor)
                    .frame(maxHeight: 20)
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(height: height)
        .contentShape(.rect)
        .animation(.default, value: isSelected)
    }
}
