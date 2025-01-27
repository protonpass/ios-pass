//
// InfoBannerView.swift
// Proton Pass - Created on 26/05/2023.
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
import SwiftUI

struct InfoBannerView: View {
    let banner: InfoBanner
    let dismiss: () -> Void
    let action: () -> Void

    static let height: CGFloat = 140

    var body: some View {
        ZStack(alignment: .topTrailing) {
            informationDisplayView
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
            if !banner.isInvite {
                closeButtonView
            }
        }

        .frame(height: Self.height)
        .background(banner.detail.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            if banner.isInvite {
                action()
            }
        }
    }
}

private extension InfoBannerView {
    var informationDisplayView: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(banner.detail.title)
                    .minimumScaleFactor(0.75)
                    .font(.body.weight(.bold))
                    .lineLimit(2)
                    .frame(maxHeight: .infinity)

                Text(banner.detail.description)
                    .minimumScaleFactor(0.75)
                    .font(.caption)
                    .frame(maxHeight: banner.detail.ctaTitle != nil ? nil : .infinity, alignment: .center)

                if let ctaTitle = banner.detail.ctaTitle {
                    ctaButtonView(ctaTitle: ctaTitle)
                }
            }
            .foregroundStyle(banner.detail.foregroundColor)
            .padding(.vertical, 16)

            Spacer()

            if let icon = banner.detail.icon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 64)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

private extension InfoBannerView {
    var closeButtonView: some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .resizable()
                .frame(width: 12, height: 12)
                .scaledToFit()
                .foregroundStyle(banner.detail.closeButtonColor)
        }
        .padding(10)
        .buttonStyle(.plain)
    }
}

private extension InfoBannerView {
    @ViewBuilder
    func ctaButtonView(ctaTitle: String) -> some View {
        switch banner.detail.typeOfCtaButton {
        case .text:
            Button(action: action) {
                Label {
                    Text(ctaTitle)
                        .minimumScaleFactor(0.75)
                        .font(.caption2.weight(.semibold))
                } icon: {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 10)
                }.labelStyle(.rightIcon)
            }
            .buttonStyle(.plain)
            .frame(maxHeight: 17)
        case let .capsule(titleColor, backgroundColor):
            CapsuleTextButton(title: ctaTitle,
                              titleColor: titleColor,
                              font: .footnote,
                              backgroundColor: backgroundColor,
                              height: 20,
                              maxWidth: nil,
                              action: action)
        }
    }
}

#Preview("InfoBannerView Preview") {
    InfoBannerView(banner: InfoBanner.autofill,
                   dismiss: {},
                   action: {})
}
