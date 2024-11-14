//
// InAppModalView.swift
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

public struct InAppModalView: View {
    let notification: InAppNotification
    let borderColor: UIColor = PassColor.inputBorderNorm
    let onTap: (InAppNotification) -> Void
    let onClose: (InAppNotification) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(notification: InAppNotification,
                onTap: @escaping (InAppNotification) -> Void,
                onClose: @escaping (InAppNotification) -> Void) {
        self.notification = notification
        self.onTap = onTap
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 24) {
                if let url = notification.content.imageUrl {
                    AsyncImage(url: URL(string: url),
                               content: { image in
                                   image.resizable()
                                       .aspectRatio(contentMode: .fit)
                                       .frame(height: 180)
                               },
                               placeholder: {
                                   ProgressView()
                               })
                               .padding(.top, 30)
                }

                Spacer()

                VStack(spacing: 12) {
                    Text(verbatim: notification.content.title)
                        .font(.title.weight(.medium))
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(verbatim: notification.content.message)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer()
                if let cta = notification.content.cta {
                    CapsuleTextButton(title: cta.text,
                                      titleColor: PassColor.textInvert,
                                      backgroundColor: PassColor.interactionNormMajor2,
                                      height: 48,
                                      action: { onTap(notification) })
                        .padding(.horizontal, DesignConstant.sectionPadding)
                    Spacer()
                }
            }
            .padding(DesignConstant.sectionPadding)
            .background(PassColor.backgroundWeak.toColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.backgroundNorm,
                         backgroundColor: PassColor.textNorm,
                         accessibilityLabel: "Close",
                         type: .custom(buttonSize: 30, iconSize: 25),
                         action: {
                             dismiss()
                             onClose(notification)
                         })
                         .padding()
        }
        .background(PassColor.backgroundWeak.toColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
