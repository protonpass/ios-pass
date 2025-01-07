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
                Text("Attachments")
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.75)
                Text("You can attach files to items for a better organization")
                    .font(.callout)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()

            ZStack(alignment: .topTrailing) {
                Image(uiImage: PassIcon.fileAttachments)
                    .resizable()
                    .scaledToFit()

                Image(uiImage: IconProvider.crossCircleFilled)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                    .foregroundStyle(PassColor.textNorm.toColor)
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
        EllipticalGradient(stops:
            [
                Gradient.Stop(color: Color(red: 0.57, green: 0.32, blue: 0.92),
                              location: 0.00),
                Gradient.Stop(color: Color(red: 0.36, green: 0.33, blue: 0.93),
                              location: 1.00)
            ],
            center: UnitPoint(x: 0.85, y: 0.19))
            .opacity(0.5)
            .clipShape(roundedRectangle)
            .overlay(roundedRectangle.strokeBorder(Color.white.opacity(0.1), lineWidth: 2))
            .padding(2)
    }

    var roundedRectangle: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16)
    }
}
