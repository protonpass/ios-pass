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

public enum VaultRowMode: Equatable {
    case view(isSelected: Bool, isHidden: Bool, action: ((Share) -> Void)?)
    case organise(isHidden: Bool)

    var isView: Bool {
        if case .view = self {
            true
        } else {
            false
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.view(lIsSelected, lIsHidden, _), .view(rIsSelected, rIsHidden, _)):
            lIsSelected == rIsSelected && lIsHidden == rIsHidden
        case let (.organise(lIsHidden), .organise(rIsHidden)):
            lIsHidden == rIsHidden
        default:
            false
        }
    }
}

public struct VaultRow<Thumbnail: View>: View {
    private let thumbnail: () -> Thumbnail
    private let title: String
    private let itemCount: Int
    private let share: Share?
    private let mode: VaultRowMode
    private let maxWidth: CGFloat?
    private let height: CGFloat

    public init(@ViewBuilder thumbnail: @escaping () -> Thumbnail,
                title: String,
                itemCount: Int,
                share: Share? = nil,
                mode: VaultRowMode = .view(isSelected: false, isHidden: false, action: nil),
                maxWidth: CGFloat? = .infinity,
                height: CGFloat = 70) {
        self.thumbnail = thumbnail
        self.title = title
        self.itemCount = itemCount
        self.share = share
        self.mode = mode
        self.maxWidth = maxWidth
        self.height = height
    }

    public var body: some View {
        HStack(spacing: 16) {
            if case let .organise(isHidden) = mode {
                Image(systemName: isHidden ? "checkmark.square.fill" : "square")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 20)
                    .foregroundStyle(PassColor.interactionNormMajor2.toColor)
            }

            ZStack(alignment: .bottomTrailing) {
                thumbnail()
                if case let .view(isSelected, isHidden, _) = mode, isSelected || isHidden {
                    let icon: UIImage? = if isSelected {
                        IconProvider.checkmark
                    } else if isHidden {
                        IconProvider.eyeSlash
                    } else {
                        nil
                    }

                    if let icon {
                        Image(uiImage: icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(PassColor.textInvert.toColor)
                            .padding(2)
                            .background(PassColor.interactionNormMajor2.toColor)
                            .frame(height: 20)
                            .clipShape(Circle())
                            .offset(x: 5, y: 5)
                    }
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

            if mode.isView, let share {
                HStack(spacing: 4) {
                    Image(uiImage: IconProvider.usersPlus)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                        .frame(maxHeight: 20)
                    if share.newUserInvitesReady > 0 {
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
                    if case let .view(_, _, action) = mode {
                        action?(share)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(height: height)
        .contentShape(.rect)
        .animation(.default, value: mode)
    }
}
