//
// InAppPromoView.swift
// Proton Pass - Created on 08/10/2025.
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
import Entities
import ProtonCoreUIFoundations
import SwiftUI

public struct InAppPromoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var backgroundLoaded = false
    private let notification: InAppNotification
    private let promoContents: InAppNotificationPromoContents
    private let onAppear: () -> Void
    private let onDisappear: () -> Void
    private let onTap: () -> Void
    private let onClose: () -> Void
    private let onNotShowAgain: () -> Void

    private var themedContents: InAppNotificationPromoThemedContents {
        colorScheme == .dark ?
            promoContents.darkThemeContents : promoContents.lightThemeContents
    }

    public init(notification: InAppNotification,
                promoContents: InAppNotificationPromoContents,
                onAppear: @escaping () -> Void,
                onDisappear: @escaping () -> Void,
                onTap: @escaping () -> Void,
                onClose: @escaping () -> Void,
                onNotShowAgain: @escaping () -> Void) {
        self.notification = notification
        self.promoContents = promoContents
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        self.onTap = onTap
        self.onClose = onClose
        self.onNotShowAgain = onNotShowAgain
    }

    public var body: some View {
        ZStack {
            backgroundImage
                .ignoresSafeArea(.all)

            VStack {
                Spacer()
                contentImage
                Spacer()
                Button(action: {
                    dismiss()
                    onNotShowAgain()
                }, label: {
                    Text(verbatim: promoContents.closePromoText)
                        .foregroundStyle(foregroundColor)
                })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .opacity(backgroundLoaded ? 1 : 0)

            closeButton
        }
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
        .interactiveDismissDisabled()
    }
}

private extension InAppPromoView {
    var backgroundImage: some View {
        AsyncImage(url: URL(string: themedContents.backgroundImageUrl),
                   content: { image in
                       image
                           .resizable()
                           .onAppear {
                               backgroundLoaded = true
                           }
                   }, placeholder: {
                       EmptyView()
                   })
                   .onTapGesture(perform: ctaAction)
    }

    var contentImage: some View {
        AsyncImage(url: URL(string: themedContents.contentImageUrl),
                   content: { image in
                       image
                           .resizable()
                           .scaledToFit()
                   }, placeholder: {
                       ProgressView()
                   })
                   .onTapGesture(perform: ctaAction)
    }

    var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                    onClose()
                }, label: {
                    Image(uiImage: IconProvider.crossCircleFilled)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32)
                        .foregroundStyle(foregroundColor)
                        .padding(.trailing, 16)
                        .padding(.top, UIDevice.current.isIpad ? 16 : 0)
                })
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var foregroundColor: Color {
        Color(hex: themedContents.closePromoTextColor)
    }

    func ctaAction() {
        dismiss()
        if notification.content.cta != nil {
            onTap()
        }
    }
}
