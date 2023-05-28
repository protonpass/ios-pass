//
// InfoBannerViewStack.swift
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

import SwiftUI

struct InfoBannerViewStack: View {
    private let offset: CGFloat = 16
    private let numOfVisibleBanners = 3
    let banners: [InfoBanner]
    let dismiss: (InfoBanner) -> Void
    let action: (InfoBanner) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(Array(banners.enumerated()), id: \.element) { index, banner in
                InfoBannerView(banner: banner,
                               dismiss: { dismiss(banner) },
                               action: { action(banner) })
                .offset(y: -CGFloat(index) * offset)
                .scaleEffect(1.0 - (CGFloat(index) * 0.1))
                .brightness(brightness(for: index))
                .opacity(index <= numOfVisibleBanners - 1 ? 1 : 0)
                .zIndex(Double(banners.count - index))
            }
        }
        .animation(.default, value: banners.count)
        .frame(height: height)
    }

    private func brightness(for index: Int) -> Double {
        max(-Double(index) / Double(banners.count), -0.5)
    }

    private var height: CGFloat {
        if banners.isEmpty {
            return 0
        } else {
            let totalOffset = CGFloat(min(banners.count, numOfVisibleBanners) - 2) * offset
            return InfoBannerView.height + totalOffset
        }
    }
}
