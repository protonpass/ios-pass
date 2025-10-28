//
// UpsellingView.swift
// Proton Pass - Created on 20/10/2023.
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

// periphery:ignore:all

// swiftlint:disable:next todo
// TODO: Either refactor or delete as no more used by new upsell flow

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct UpsellElement: Sendable, Hashable, Identifiable {
    public let id = UUID().uuidString
    let icon: UIImage
    let title: String
    let color: Color?

    public init(icon: UIImage, title: String, color: Color? = nil) {
        self.icon = icon
        self.title = title
        self.color = color
    }
}

public struct UpsellingViewConfiguration: Sendable, Hashable {
    let icon: UIImage
    let title: String
    let description: String
    let upsellElements: [UpsellElement]
    let ctaTitle: String

    public init(icon: UIImage,
                title: String,
                description: String,
                upsellElements: [UpsellElement],
                ctaTitle: String) {
        self.icon = icon
        self.title = title
        self.description = description
        self.upsellElements = upsellElements
        self.ctaTitle = ctaTitle
    }
}

public struct UpsellingView: View {
    @Environment(\.dismiss) private var dismiss
    private let onUpgrade: () -> Void
    private let configuration: UpsellingViewConfiguration

    public init(configuration: UpsellingViewConfiguration, onUpgrade: @escaping () -> Void) {
        self.onUpgrade = onUpgrade
        self.configuration = configuration
    }

    public var body: some View {
        mainContainer
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .foregroundStyle(PassColor.textNorm)
            .background(PassColor.backgroundNorm)
            .edgesIgnoringSafeArea(.top)
    }
}

private extension UpsellingView {
    var mainContainer: some View {
        GeometryReader { proxy in
            VStack(alignment: .center) {
                Spacer()
                Image(uiImage: configuration.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: proxy.size.width * 0.75)

                Text(configuration.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PassColor.textNorm)

                Text(configuration.description)
                    .padding(.bottom)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PassColor.textWeak)

                VStack(spacing: 16) {
                    ForEach(configuration.upsellElements) { element in
                        perkRow(element: element)
                    }
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .padding(.horizontal, DesignConstant.sectionPadding * 2)
                .roundedDetailSection()
                Spacer()

                CapsuleTextButton(title: configuration.ctaTitle,
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.interactionNormMajor2,
                                  height: 48,
                                  action: onUpgrade)
                    .padding(.horizontal, DesignConstant.sectionPadding)

                CapsuleTextButton(title: #localized("Not now", bundle: .module),
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: .clear,
                                  height: 48,
                                  action: dismiss.callAsFunction)
                    .padding(.horizontal, DesignConstant.sectionPadding)
            }
        }
    }

    func perkRow(element: UpsellElement) -> some View {
        Label(title: {
            Text(element.title)
        }, icon: {
            Image(uiImage: element.icon)
                .renderingMode(element.color != nil ? .template : .original)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 20)
                .foregroundStyle(element.color ?? PassColor.interactionNormMajor2)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
