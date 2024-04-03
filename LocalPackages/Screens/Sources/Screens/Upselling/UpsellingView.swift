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

public struct UpsellingView: View {
    @Environment(\.dismiss) private var dismiss
    private let onUpgrade: () -> Void

    public init(onUpgrade: @escaping () -> Void) {
        self.onUpgrade = onUpgrade
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
            Image(uiImage: PassIcon.passPlus)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            Text("Stay safer online", bundle: .module)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textNorm.toColor)

            Text("Unlock advanced security features and detailed logs to safeguard your online presence.",
                 bundle: .module)
                .padding(.bottom)
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textNorm.toColor)

            VStack {
                perkRow(title: "Proton sentinel",
                        icon: IconProvider.user,
                        iconTintColor: PassColor.interactionNormMajor2)
                perkRow(title: "Dark Web monitoring",
                        icon: PassIcon.shield2,
                        iconTintColor: PassColor.interactionNormMajor2)
                perkRow(title: "Integrated 2FA authenticator",
                        icon: IconProvider.lock,
                        iconTintColor: PassColor.interactionNormMajor2)
                perkRow(title: "Unlimited hide-my-email aliases",
                        icon: IconProvider.alias,
                        iconTintColor: PassColor.interactionNormMajor2)
                perkRow(title: "Vault sharing (up to 10 people)",
                        icon: IconProvider.userPlus,
                        iconTintColor: PassColor.interactionNormMajor2)
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

    private func perkRow(title: LocalizedStringKey, icon: UIImage, iconTintColor: UIColor? = nil) -> some View {
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

#Preview {
    UpsellingView(onUpgrade: {})
}
