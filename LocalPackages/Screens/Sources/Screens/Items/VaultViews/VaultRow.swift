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
import Entities
import ProtonCoreUIFoundations
import SwiftUI

public struct VaultRow<Thumbnail: View>: View {
    private let thumbnail: () -> Thumbnail
    private let title: String
    private let itemCount: Int
    private let share: Share?
    private let isSelected: Bool
    private let showBadge: Bool
    private let maxWidth: CGFloat?
    private let height: CGFloat
    private let shareAction: ((Share) -> Void)?

    public init(@ViewBuilder thumbnail: @escaping () -> Thumbnail,
                title: String,
                itemCount: Int,
                share: Share? = nil,
                isSelected: Bool,
                showBadge: Bool = false,
                maxWidth: CGFloat? = .infinity,
                height: CGFloat = 70,
                shareAction: ((Share) -> Void)? = nil) {
        self.thumbnail = thumbnail
        self.title = title
        self.itemCount = itemCount
        self.share = share
        self.isSelected = isSelected
        self.showBadge = showBadge
        self.maxWidth = maxWidth
        self.height = height
        self.shareAction = shareAction
    }

    public var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                thumbnail()
                if isSelected {
                    Image(uiImage: IconProvider.checkmarkCircleFilled)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                        .frame(maxHeight: 20)
                        .clipShape(Circle())
                        .offset(x: 5, y: 5)
                }
            }

            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(PassColor.textNorm.toColor)

                if itemCount == 0 {
                    Text("Empty", bundle: .module)
                        .placeholderText()
                } else {
                    Text("\(itemCount) item(s)", bundle: .module)
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak.toColor)
                }
            }

            if maxWidth != nil {
                Spacer()
            }

            if let share {
                HStack(spacing: 4) {
                    Image(uiImage: IconProvider.usersPlus)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                        .frame(maxHeight: 20)
                    if showBadge {
                        Image(uiImage: IconProvider.exclamationCircleFilled)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(PassColor.signalDanger.toColor)
                            .frame(maxHeight: 16)
                            .offset(y: -10)
                    }
                    if share.shared {
                        Text(verbatim: "\(share.members)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(PassColor.interactionNormMinor1.toColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PassColor.interactionNormMajor2.toColor)
                            .cornerRadius(20)
                    }
                }
                .padding(10)
                .background(PassColor.interactionNormMinor1.toColor)
                .cornerRadius(20)
                .buttonEmbeded {
                    shareAction?(share)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(height: height)
        .contentShape(.rect)
        .animation(.default, value: isSelected)
    }
}
