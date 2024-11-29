//
// VaultLabel.swift
// Proton Pass - Created on 13/04/2023.
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
import Entities
import SwiftUI

struct VaultLabel: View {
    let vault: Share

    var body: some View {
        Label(title: {
            Text(vault.name)
                .font(.footnote)
        }, icon: {
            Image(uiImage: vault.displayPreferences.icon.icon.smallImage)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
        })
        .foregroundStyle(PassColor.textWeak.toColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
