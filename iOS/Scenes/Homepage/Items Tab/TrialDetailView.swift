//
// TrialDetailView.swift
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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct TrialDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let daysLeft: Int
    let onUpgrade: () -> Void
    let onLearnMore: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Image(uiImage: PassIcon.trialDetail)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("Your welcome gift")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Enjoy next-level password management")
                    .padding(.bottom)
                    .multilineTextAlignment(.center)

                VStack {
                    perk(title: #localized("20 vaults"), icon: PassIcon.trialVaults)
                    PassDivider()
                    perk(title: #localized("Unlimited email aliases"),
                         icon: IconProvider.alias,
                         iconTintColor: PassColor.aliasInteractionNorm)
                    PassDivider()
                    perk(title: #localized("Integrated 2FA authenticator"), icon: PassIcon.trial2FA)
                    PassDivider()
                    perk(title: #localized("Custom fields"), icon: PassIcon.trialCustomFields)
                }
                .padding()
                .background(PassColor.inputBackgroundNorm.toColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.vertical, 32)

                Button(action: onUpgrade) {
                    Text("Upgrade now")
                        .font(.title3)
                        .padding(16)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .background(LinearGradient(colors: [
                        .init(red: 174 / 255, green: 80 / 255, blue: 96 / 255),
                        .init(red: 113 / 255, green: 77 / 255, blue: 255 / 255)
                    ], // swiftlint:disable:this literal_expression_end_indentation
                    startPoint: .leading,
                    endPoint: .trailing))
                .clipShape(Capsule())

                Text("\(daysLeft) trial day(s) left")
                    .font(.callout)
                    .padding(.top)

                Button(action: onLearnMore) {
                    Text("Learn more")
                        .font(.callout)
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                        .underline(color: PassColor.interactionNormMajor2.toColor)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .foregroundStyle(PassColor.textNorm.toColor)
            .background(PassColor.backgroundNorm.toColor)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Close",
                                 action: dismiss.callAsFunction)
                }
            }
        }
    }

    private func perk(title: String, icon: UIImage, iconTintColor: UIColor? = nil) -> some View {
        Label(title: {
            Text(title)
                .minimumScaleFactor(0.75)
        }, icon: {
            Image(uiImage: icon)
                .renderingMode(iconTintColor != nil ? .template : .original)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 32)
                .if(iconTintColor) { view, color in
                    view
                        .foregroundStyle(color.toColor)
                }
        })
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
