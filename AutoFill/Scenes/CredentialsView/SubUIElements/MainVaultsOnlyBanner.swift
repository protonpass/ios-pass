//
// MainVaultsOnlyBanner.swift
// Proton Pass - Created on 19/09/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import SwiftUI

struct MainVaultsOnlyBanner: View {
    var onTap: () -> Void

    var body: some View {
        ZStack {
            Text("Your plan only allows to use items from your first 2 vaults for autofill purposes.")
                .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                Text(verbatim: " ") +
                Text("Upgrade now")
                .underline(color: PassColor.interactionNormMajor1.toColor)
                .adaptiveForegroundStyle(PassColor.interactionNormMajor1.toColor)
        }
        .padding()
        .background(PassColor.interactionNormMinor1.toColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onTap)
    }
}
