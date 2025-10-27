//
// OnboardingPassPlusView.swift
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
import SwiftUI

struct OnboardingPassPlusView: View {
    let detailColumnWidth: CGFloat = 86
    let features: [FeatureUiModel] =
        [
            .init(description: "Hide-my-email aliases",
                  lowerPerk: .number(10),
                  higherPerk: .infinite),
            .init(description: "Built-in 2FA",
                  lowerPerk: .unavailable,
                  higherPerk: .available),
            .init(description: "Vault, item & link sharing",
                  lowerPerk: .unavailable,
                  higherPerk: .available),
            .init(description: "Credit cards",
                  lowerPerk: .unavailable,
                  higherPerk: .infinite),
            .init(description: "Dark Web Monitoring",
                  lowerPerk: .unavailable,
                  higherPerk: .available),
            .init(description: "File attachments",
                  lowerPerk: .unavailable,
                  higherPerk: .available)
        ]

    var body: some View {
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

private extension OnboardingPassPlusView {
    var table: some View {
        LazyVGrid(columns:
            [
                .init(.flexible()),
                .init(.fixed(detailColumnWidth)),
                .init(.fixed(detailColumnWidth))
            ],
            spacing: DesignConstant.sectionPadding * 2) {
                Text("What's included", bundle: .module)
                    .font(.callout)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Free", bundle: .module)
                    .fontWeight(.bold)

                PassPlusTitle()

                ForEach(features) { feature in
                    Text(feature.description)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    PerkDetailView(perk: feature.lowerPerk)
                    PerkDetailView(perk: feature.higherPerk)
                }
            }
            .themedForegroundStyle(dark: Color.white, light: PassColor.textNorm)
            .padding(.vertical)
    }
}

struct PassPlusTitle: View {
    var body: some View {
        Text(verbatim: "Plus")
            .fontWeight(.bold)
            .padding(.vertical, 4)
            .padding(.horizontal)
            .background(ThemedColor(dark: Color(red: 0.05, green: 0.05, blue: 0.05, opacity: 0.6),
                                    light: PassColor.newBackgroundStrong))
            .clipShape(.capsule)
    }
}
