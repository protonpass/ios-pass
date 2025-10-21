//
// PerkDetailView.swift
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

struct PerkDetailView: View {
    let perk: PerkDetail
    let isOnboarding: Bool

    var body: some View {
        Group {
            switch perk {
            case .available:
                Image(uiImage: IconProvider.checkmarkCircleFilled)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)

            case .unavailable:
                Text(verbatim: "-")
                    .font(.title2)

            case .infinite:
                Text(verbatim: "∞")
                    .font(.title2)

            case let .number(value):
                Text(verbatim: "\(value)")

            case let .text(value):
                Text(value)
            }
        }
        .foregroundStyle(isOnboarding ? .white : PassColor.textNorm.toColor)
    }
}
