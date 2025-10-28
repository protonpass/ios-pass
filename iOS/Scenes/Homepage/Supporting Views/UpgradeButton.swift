//
// UpgradeButton.swift
// Proton Pass - Created on 03/05/2023.
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

struct UpgradeButton: View {
    let backgroundColor: Color
    var height: CGFloat = 40
    var maxWidth: CGFloat? = .infinity
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("Upgrade")
                    .font(.callout)
                Image(uiImage: IconProvider.arrowOutSquare)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 16)
            }
            .frame(height: height)
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, 16)
            .foregroundStyle(PassColor.textInvert)
            .background(backgroundColor)
            .clipShape(Capsule())
        }
    }
}

/// Text button without background color
struct UpgradeButtonLite: View {
    let foregroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("Upgrade")
                Image(uiImage: IconProvider.arrowOutSquare)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 16)
            }
            .foregroundStyle(foregroundColor)
            .contentShape(.rect)
        }
    }
}
