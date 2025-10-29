//
// FileAttachmentsBanner.swift
// Proton Pass - Created on 18/11/2024.
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
//

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

public struct FileAttachmentsBanner: View {
    let isShown: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    public init(isShown: Bool,
                onTap: @escaping () -> Void,
                onClose: @escaping () -> Void) {
        self.isShown = isShown
        self.onTap = onTap
        self.onClose = onClose
    }

    public var body: some View {
        if isShown {
            GeometryReader { proxy in
                ZStack {
                    gradientBackground
                    content(proxy.size)
                }
            }
            .frame(height: 108)
            .frame(maxWidth: .infinity)
        }
    }
}

private extension FileAttachmentsBanner {
    func content(_ size: CGSize) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Attachments", bundle: .module)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.75)
                Text("You can attach files to items for a better organization", bundle: .module)
                    .font(.callout)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()

            ZStack(alignment: .topTrailing) {
                PassIcon.fileAttachments
                    .resizable()
                    .scaledToFit()

                IconProvider.crossCircleFilled
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                    .foregroundStyle(UIColor.darkGray.toColor)
                    .padding(12)
                    .buttonEmbeded(action: onClose)
            }
            .frame(maxWidth: size.width / 3)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(roundedRectangle)
        .contentShape(.rect)
        .onTapGesture(perform: onTap)
    }

    var gradientBackground: some View {
        BannerEllipticalGradient()
            .clipShape(roundedRectangle)
            .overlay(roundedRectangle.strokeBorder(Color.white.opacity(0.1), lineWidth: 2))
    }

    var roundedRectangle: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16)
    }
}
