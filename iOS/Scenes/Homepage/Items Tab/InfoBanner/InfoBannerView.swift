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

import SwiftUI
import UIComponents

struct InfoBannerView: View {
    let banner: InfoBanner
    let dismiss: () -> Void
    let action: () -> Void

    static let height: CGFloat = 140

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                        .frame(maxWidth: 20, maxHeight: 20)
                        .foregroundColor(Color(uiColor: PassColor.textInvert))
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(banner.detail.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(banner.detail.description)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    if let ctaTitle = banner.detail.ctaTitle {
                        Button(action: action) {
                            Label(ctaTitle, systemImage: "chevron.right")
                                .labelStyle(.rightIcon)
                                .font(.caption.weight(.semibold))
                        }
                    }

                    Spacer()
                }
                .foregroundColor(Color(uiColor: PassColor.textInvert))
                .frame(maxWidth: .infinity, alignment: .leading)

                if let icon = banner.detail.icon {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 100)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(uiColor: banner.detail.backgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(height: Self.height)
    }
}
