//
// ShareItemButton.swift
// Proton Pass - Created on 03/12/2024.
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
import Factory
import ProtonCoreUIFoundations
import SwiftUI

// struct ShareItemButton: View {
//    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
//    let share: Share
//    let itemContent: ItemContent
//
//    var body: some View {
//        Button { router.present(for: .manageSharedShare(share, itemContent, .none)) } label: {
//            HStack(spacing: 3) {
//                Image(uiImage: IconProvider.usersFilled)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 16, height: 16)
//                    .foregroundStyle(itemContent.contentData.type.normMajor2Color
//                        .toColor)
//                    .padding(.leading, 8)
//                Text(verbatim: "\(getShareNumbers)")
//                    .font(.caption.weight(.medium))
//                    .fontWeight(.medium)
//                    .foregroundStyle(itemContent.contentData.type.normMinor1Color
//                        .toColor)
//                    .padding(.horizontal, 7)
//                    .background(itemContent.contentData.type.normMajor2Color.toColor)
//                    .clipShape(Circle())
//                    .padding(.trailing, 4)
//            }
//            .padding(.vertical, 4)
//            .frame(minHeight: 30)
//        }
//        .background(itemContent.contentData.type.normMinor1Color.toColor)
//        .clipShape(Capsule())
//    }
//
//    private var getShareNumbers: Int {
//        var members = 0
//        if share.isVaultRepresentation, share.shared {
//            members = share.members
//        }
//        if itemContent.item.shareCount > members {
//            members += itemContent.item.shareCount
//        }
//
//        return members
//    }
// }
