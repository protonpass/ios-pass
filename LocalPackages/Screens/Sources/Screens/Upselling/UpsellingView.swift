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

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

public struct UpsellElement: Sendable, Hashable, Identifiable {
    public let id = UUID().uuidString
    let icon: UIImage
    let title: String
    let color: UIColor

    public init(icon: UIImage, title: String, color: UIColor) {
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

    public init(icon: UIImage,
                title: String,
                description: String,
                upsellElements: [UpsellElement]) {
        self.icon = icon
        self.title = title
        self.description = description
        self.upsellElements = upsellElements
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
            .foregroundColor(PassColor.textNorm.toColor)
            .background(PassColor.backgroundNorm.toColor)
            .edgesIgnoringSafeArea(.top)
    }
}

private extension UpsellingView {
    var mainContainer: some View {
        VStack(alignment: .center) {
            Image(uiImage: configuration.icon)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            Text(configuration.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textNorm.toColor)

            Text(configuration.description)
                .padding(.bottom)
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textNorm.toColor)

            VStack {
                ForEach(configuration.upsellElements) { element in
                    perkRow(title: element.title,
                            icon: element.icon,
                            iconTintColor: element.color)
                }
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .padding(.horizontal, DesignConstant.sectionPadding * 2)
            .roundedDetailSection()
            Spacer()

            CapsuleTextButton(title: "Get Pass Plus",
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNormMajor2,
                              action: onUpgrade)
                .padding(.horizontal, DesignConstant.sectionPadding)

            CapsuleTextButton(title: "Not Now",
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: .clear,
                              action: dismiss.callAsFunction)
                .padding(.horizontal, DesignConstant.sectionPadding)
        }
    }

    private func perkRow(title: String, icon: UIImage, iconTintColor: UIColor? = nil) -> some View {
        Label(title: {
            Text(title)
                .minimumScaleFactor(0.75)
        }, icon: {
            Image(uiImage: icon)
                .renderingMode(iconTintColor != nil ? .template : .original)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 32)
                .foregroundColor(iconTintColor?.toColor)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
