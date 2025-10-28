//
// OnboardingProtonUnlimitedView.swift
// Proton Pass - Created on 10/04/2025.
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
//

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

struct OnboardingProtonUnlimitedView: View {
    let detailColumnWidth: CGFloat = 125
    let features: [FeatureUiModel] =
        [
            .init(description: "Storage",
                  lowerPerk: .text("10 GB"),
                  higherPerk: .text("500 GB")),
            .init(description: "Extra email addresses",
                  lowerPerk: .number(1),
                  higherPerk: .number(15)),
            .init(description: "VPN Devices",
                  lowerPerk: .number(1),
                  higherPerk: .number(10)),
            .init(description: "VPN Speed",
                  lowerPerk: .text("Medium"),
                  higherPerk: .text("Highest"))
        ]

    var body: some View {
        VStack {
            Text("The best of Proton with one subscription.", bundle: .module)
                .font(.callout)
                .themedForegroundStyle(dark: .white, light: PassColor.textNorm)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
            protonApps
                .padding(.vertical)
            ZStack {
                HStack {
                    Spacer()
                    ThemedColor(dark: PassColor.backgroundMedium,
                                light: PassColor.newBackgroundStrong)
                        .frame(width: detailColumnWidth)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                table
            }
        }
    }
}

private extension OnboardingProtonUnlimitedView {
    var protonApps: some View {
        HStack {
            app(name: "Pass", icon: PassIcon.passIcon)
            app(name: "Mail", icon: IconProvider.mailMainTransparent)
            app(name: "Calendar", icon: IconProvider.calendarMainTransparent)
            app(name: "Drive", icon: IconProvider.driveMainTransparent)
            app(name: "VPN", icon: IconProvider.vpnMainTransparent)
        }
        .frame(maxWidth: .infinity)
    }

    func app(name: String, icon: UIImage) -> some View {
        VStack(alignment: .center) {
            Image(uiImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32)
            Text(verbatim: name)
                .font(.caption)
                .themedForegroundStyle(dark: .white, light: PassColor.textNorm)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    var table: some View {
        LazyVGrid(columns:
            [
                .init(.flexible()),
                .init(.fixed(80)),
                .init(.fixed(detailColumnWidth))
            ],
            spacing: DesignConstant.sectionPadding * 2) {
                Text("What's included", bundle: .module)
                    .font(.callout)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                PassPlusTitle()

                Text(verbatim: "Unlimited")
                    .fontWeight(.bold)
                    .padding(.vertical, 4)
                    .padding(.horizontal)
                    .background(.white)
                    .foregroundStyle(PassColor.textInvert)
                    .clipShape(.capsule)

                ForEach(features) { feature in
                    Text(feature.description)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    PerkDetailView(perk: feature.lowerPerk)
                    PerkDetailView(perk: feature.higherPerk)
                }
            }
            .themedForegroundStyle(dark: .white, light: PassColor.textNorm)
            .padding(.vertical)
    }
}
