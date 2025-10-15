//
// InAppBannerView.swift
// Proton Pass - Created on 07/11/2024.
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

public struct InAppBannerView: View {
    private let notification: InAppNotification
    private let borderColor: UIColor = PassColor.inputBorderNorm
    private let onAppear: () -> Void
    private let onDisappear: () -> Void
    private let onTap: () -> Void
    private let onClose: () -> Void

    public init(notification: InAppNotification,
                onAppear: @escaping () -> Void,
                onDisappear: @escaping () -> Void,
                onTap: @escaping () -> Void,
                onClose: @escaping () -> Void) {
        self.notification = notification
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        self.onTap = onTap
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: DesignConstant.sectionPadding) {
                if let imageUrl = notification.content.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url,
                               content: { image in
                                   image.resizable()
                                       .aspectRatio(contentMode: .fit)
                                       .frame(maxWidth: 40, maxHeight: 40)
                               },
                               placeholder: {
                                   ProgressView()
                               })
                }

                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text(verbatim: notification.content.title)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: notification.content.message)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .minimumScaleFactor(0.8)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                if notification.content.cta != nil {
                    ItemDetailSectionIcon(icon: IconProvider.chevronRight, width: 20)
                }
            }
            .padding(12)
            .background(PassColor.backgroundWeak.toColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor.toColor, lineWidth: 1))
            .contentShape(.rect)
            .onTapGesture {
                if notification.content.cta != nil {
                    onTap()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.textNorm,
                         backgroundColor: PassColor.backgroundNorm,
                         accessibilityLabel: "Close",
                         type: .custom(buttonSize: 25, iconSize: 16),
                         action: onClose)
                .overlay(Circle()
                    .stroke(borderColor.toColor, lineWidth: 2))
                .padding(4)
                .background(PassColor.backgroundNorm.toColor)
                .clipShape(.circle)
                .offset(x: 13, y: -13)
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
    }
}
