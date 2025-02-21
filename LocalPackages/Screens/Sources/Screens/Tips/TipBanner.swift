//
// TipBanner.swift
// Proton Pass - Created on 06/01/2025.
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public extension TipBanner {
    struct Configuration {
        let cornerRadius: CGFloat
        let contentPadding: CGFloat
        let arrowMode: ArrowMode
        let arrowSize: CGSize
        let title: LocalizedStringKey?
        let description: LocalizedStringKey
        let cta: CTA?
        let trailingBackground: TrailingBackground?

        public enum ArrowMode {
            case none
            case topLeft(padding: CGFloat)
            case topRight(padding: CGFloat)
        }

        public struct CTA {
            let title: String
            let action: () -> Void

            public init(title: String,
                        action: @escaping () -> Void) {
                self.title = title
                self.action = action
            }
        }

        public struct TrailingBackground {
            let image: UIImage
            let offset: CGSize

            public init(image: UIImage, offset: CGSize) {
                self.image = image
                self.offset = offset
            }
        }

        var topPadding: CGFloat {
            switch arrowMode {
            case .none:
                contentPadding
            case .topLeft, .topRight:
                contentPadding + arrowSize.height
            }
        }

        public init(cornerRadius: CGFloat = 16,
                    contentPadding: CGFloat = 16,
                    arrowMode: ArrowMode,
                    arrowSize: CGSize = .init(width: 20, height: 10),
                    title: LocalizedStringKey? = nil,
                    description: LocalizedStringKey,
                    cta: CTA? = nil,
                    trailingBackground: TrailingBackground? = nil) {
            self.cornerRadius = cornerRadius
            self.contentPadding = contentPadding
            self.arrowMode = arrowMode
            self.arrowSize = arrowSize
            self.title = title
            self.description = description
            self.cta = cta
            self.trailingBackground = trailingBackground
        }
    }
}

public struct TipBanner: View {
    private let configuration: Configuration
    private let onDismiss: () -> Void

    public init(configuration: Configuration, onDismiss: @escaping () -> Void) {
        self.configuration = configuration
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            BannerEllipticalGradient()
            trailingBackground

            HStack {
                VStack(alignment: .leading) {
                    if let title = configuration.title {
                        Text(title)
                            .fontWeight(.medium)
                    } else {
                        Text(#localized("Did you know?", bundle: .module))
                            .fontWeight(.medium)
                    }

                    Text(configuration.description)
                }
                .environment(\.colorScheme, .dark)
                .foregroundStyle(PassColor.textNorm.toColor)
                .tint(PassColor.textNorm.toColor)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)

                if let cta = configuration.cta {
                    CapsuleTextButton(title: cta.title,
                                      titleColor: PassColor.textInvert,
                                      font: .callout.weight(.medium),
                                      backgroundColor: .white,
                                      maxWidth: nil,
                                      action: cta.action)
                        .minimumScaleFactor(0.75)
                }
            }
            .padding(.top, configuration.topPadding)
            .padding([.horizontal, .bottom], configuration.contentPadding)

            Button(action: onDismiss) {
                Image(uiImage: IconProvider.cross)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(width: 18, height: 18)
                    .padding(.top, configuration.topPadding * 2 / 3)
                    .padding(.trailing, configuration.contentPadding * 2 / 3)
            }
            .environment(\.colorScheme, .dark)
        }
        .foregroundStyle(PassColor.textNorm.toColor)
        .clipShape(shape)
        .overlay(shape.stroke(.white.opacity(0.1), lineWidth: 1))
    }
}

private extension TipBanner {
    var shape: some Shape {
        switch configuration.arrowMode {
        case .none:
            AnyShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        case let .topLeft(padding):
            AnyShape(RoundedRectangleWithArrow(cornerRadius: configuration.cornerRadius,
                                               arrowPosition: .topLeft,
                                               arrowSize: configuration.arrowSize,
                                               arrowPadding: padding))
        case let .topRight(padding):
            AnyShape(RoundedRectangleWithArrow(cornerRadius: configuration.cornerRadius,
                                               arrowPosition: .topRight,
                                               arrowSize: configuration.arrowSize,
                                               arrowPadding: padding))
        }
    }

    @ViewBuilder
    var trailingBackground: some View {
        GeometryReader { proxy in
            if let background = configuration.trailingBackground {
                HStack {
                    Spacer()
                    Image(uiImage: background.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: proxy.size.width / 2, maxHeight: proxy.size.height)
                        .offset(background.offset)
                }
            }
        }
    }
}
