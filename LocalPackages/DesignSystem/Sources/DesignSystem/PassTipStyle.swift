//
// PassTipStyle.swift
// Proton Pass - Created on 22/03/2024.
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

import SwiftUI
import TipKit

@available(iOS 17, *)
public struct PassTipStyle: TipViewStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            if let image = configuration.image {
                image
                    .font(.system(size: 44))
                    .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                    .frame(alignment: .topLeading)
            }

            VStack(alignment: .leading) {
                if let title = configuration.title {
                    title
                        .font(.headline.bold())
                        .foregroundStyle(PassColor.textNorm.toColor)
                }

                if let message = configuration.message {
                    message
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak.toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
        .backgroundStyle(.regularMaterial)
        .overlay(alignment: .topTrailing) {
            // Close button
            Image(systemName: "multiply")
                .font(.title2)
                .foregroundStyle(.tertiary)
                .onTapGesture {
                    configuration.tip.invalidate(reason: .tipClosed)
                }
        }
        .padding()
    }
}

@available(iOS 17, *)
public extension TipViewStyle where Self == PassTipStyle {
    static var passTipStyle: PassTipStyle { .init() }
}
