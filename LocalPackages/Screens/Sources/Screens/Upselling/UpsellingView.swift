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
        ZStack(alignment: .topLeading) {
            mainContainer
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding()
                .foregroundColor(Color(uiColor: PassColor.textNorm))
                .background(Color(uiColor: PassColor.backgroundNorm))
                .edgesIgnoringSafeArea(.top)

            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
                .padding()
        }
    }
}

private extension UpsellingView {
    var mainContainer: some View {
        VStack(alignment: .center) {
            Image(uiImage: PassIcon.trialDetail)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            Text("Pass Plus")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textNorm.toColor)

            Text("Get unlimited aliases, enjoy exclusive features, and support us by subscribing to Pass Plus.")
                .padding(.bottom)
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textNorm.toColor)

            VStack {
                perkRow(title: "Unlimited email aliases",
                        icon: IconProvider.alias,
                        iconTintColor: PassColor.aliasInteractionNorm)
                PassDivider()
                perkRow(title: "Unlimited 2FA Autofill", icon: PassIcon.trial2FA)
                PassDivider()
                perkRow(title: "Sharing with up to 10 people",
                        icon: IconProvider.userPlus,
                        iconTintColor: PassColor.noteInteractionNormMajor1)
                PassDivider()
                perkRow(title: "Multiple Vaults", icon: PassIcon.trialVaults)
            }
            .padding()
            .background(PassColor.inputBackgroundNorm.toColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.vertical, 32)

            Spacer()

            GradientRoundedButton(title: "Upgrade",
                                  leadingBackgroundColor: .init(red: 174 / 255, green: 80 / 255, blue: 96 / 255),
                                  endingBackgroundColor: .init(red: 113 / 255, green: 77 / 255, blue: 255 / 255),
                                  action: onUpgrade)
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
