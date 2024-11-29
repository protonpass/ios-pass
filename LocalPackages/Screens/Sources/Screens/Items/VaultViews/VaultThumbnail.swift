//
// VaultThumbnail.swift
// Proton Pass - Created on 06/08/2024.
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
import Entities
import SwiftUI

public struct VaultThumbnail: View {
    private let vault: Share

    private var iconColor: UIColor {
        vault.mainColor
    }

    public init(vault: Share) {
        self.vault = vault
    }

    public var body: some View {
        CircleButton(icon: vault.vaultBigIcon,
                     iconColor: iconColor,
                     iconDisabledColor: iconColor.withAlphaComponent(0.75),
                     backgroundColor: iconColor.withAlphaComponent(0.16),
                     backgroundDisabledColor: iconColor.withAlphaComponent(0.08))
            .animation(.default, value: vault)
    }
}
