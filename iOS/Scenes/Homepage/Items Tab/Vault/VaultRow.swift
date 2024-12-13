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
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

// struct VaultRow<Thumbnail: View>: View {
//    let thumbnail: () -> Thumbnail
//    let title: String
//    let itemCount: Int
//    let share: Share?
//    let isSelected: Bool
//    let showBadge: Bool
//    let maxWidth: CGFloat?
//    let height: CGFloat
//    let shareAction: ((Share) -> Void?)?
//
//    init(@ViewBuilder thumbnail: @escaping () -> Thumbnail,
//         title: String,
//         itemCount: Int,
//         share: Share? = nil,
//         isSelected: Bool,
//         showBadge: Bool = false,
//         maxWidth: CGFloat? = nil,
//         height: CGFloat = 70,
//         shareAction: ((Share) -> Void?)? = nil) {
//        self.thumbnail = thumbnail
//        self.title = title
//        self.itemCount = itemCount
//        self.share = share
//        self.isSelected = isSelected
//        self.showBadge = showBadge
//        self.maxWidth = maxWidth
//        self.height = height
//        self.shareAction = shareAction
//    }
//
//    var body: some View {
//        HStack(spacing: 16) {
//            thumbnail()
//
//            VStack(alignment: .leading) {
//                Text(title)
//                    .foregroundStyle(PassColor.textNorm.toColor)
//
//                if itemCount == 0 {
//                    Text("Empty")
//                        .placeholderText()
//                } else {
//                    Text("\(itemCount) item(s)")
//                        .font(.callout)
//                        .foregroundStyle(PassColor.textWeak.toColor)
//                }
//            }
//
//            if maxWidth != nil {
//                Spacer()
//            }
//
//            if let share {
//                // TODO: make a button type for this
//                Button {
//                    shareAction?(share)
//                } label: {
//                    HStack(spacing: 4) {
//                        Image(uiImage: IconProvider.usersPlus)
//                            .resizable()
//                            .scaledToFit()
//                            .foregroundStyle(PassColor.interactionNormMajor2.toColor)
//                            .frame(maxHeight: 20)
//                        if showBadge {
//                            Image(uiImage: IconProvider.exclamationCircleFilled)
//                                .resizable()
//                                .scaledToFit()
//                                .foregroundStyle(PassColor.signalDanger.toColor)
//                                .frame(maxHeight: 16)
//                                .offset(y: -10)
//                        }
//                        if share.shared {
//                            Text(verbatim: "\(share.members)")
//                                .font(.caption)
//                                .fontWeight(.medium)
//                                .foregroundStyle(PassColor.interactionNormMinor1.toColor)
//                                .padding(.horizontal, 6)
//                                .padding(.vertical, 2)
//                                .background(PassColor.interactionNormMajor2.toColor)
//                                .cornerRadius(20)
//                        }
//                    }
//                    .padding(10)
//                    .background(PassColor.interactionNormMinor1.toColor)
//                    .cornerRadius(20)
//                }
//                .buttonStyle(.plain)
//            }
//
//            if isSelected {
//                Image(uiImage: IconProvider.checkmark)
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundStyle(PassColor.interactionNorm.toColor)
//                    .frame(maxHeight: 20)
//            }
//        }
//        .frame(maxWidth: maxWidth)
//        .frame(height: height)
//        .contentShape(.rect)
//        .animation(.default, value: isSelected)
//    }
// }

//
// public var body: some View {
////    HStack(spacing: 16) {
////        thumbnail()
//
////        VStack(alignment: .leading) {
////            Text(title)
////                .foregroundStyle(PassColor.textNorm.toColor)
////
////            if itemCount == 0 {
////                Text("Empty")
////                    .placeholderText()
////            } else {
////                Text("\(itemCount) item(s)")
////                    .font(.callout)
////                    .foregroundStyle(PassColor.textWeak.toColor)
////            }
////        }
//
////        if maxWidth != nil {
////            Spacer()
////        }
//
//        if isShared {
//            HStack(spacing: 0) {
//                Image(uiImage: IconProvider.users)
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundStyle(PassColor.textWeak.toColor)
//                    .frame(maxHeight: 20)
//                if showBadge {
//                    Image(uiImage: IconProvider.exclamationCircleFilled)
//                        .resizable()
//                        .scaledToFit()
//                        .foregroundStyle(PassColor.signalDanger.toColor)
//                        .frame(maxHeight: 16)
//                        .offset(y: -10)
//                }
//            }
//        }
//
//        if isSelected {
//            Image(uiImage: IconProvider.checkmark)
//                .resizable()
//                .scaledToFit()
//                .foregroundStyle(PassColor.interactionNorm.toColor)
//                .frame(maxHeight: 20)
//        }
//    }
//    .frame(maxWidth: maxWidth)
//    .frame(height: height)
//    .contentShape(.rect)
//    .animation(.default, value: isSelected)
// }
