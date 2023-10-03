//
// ShareOrCreateNewVaultView.swift
// Proton Pass - Created on 03/10/2023.
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

import Client
import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ShareOrCreateNewVaultView: View {
    let vault: VaultListUiModel
    let onShareVault: () -> Void
    let onCreateNewVault: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Share")
                .font(.body.bold())
                .foregroundColor(PassColor.textNorm.toColor)

            Text("Use vaults to share this item with another person")
                .foregroundColor(PassColor.textWeak.toColor)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Spacer()

            currentVault
                .padding(.bottom, 12)

            createNewVaultButton

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(PassColor.backgroundNorm.toColor)
    }
}

private extension ShareOrCreateNewVaultView {
    var currentVault: some View {
        HStack {
            VaultRow(thumbnail: {
                         CircleButton(icon: vault.vault.displayPreferences.icon.icon.bigImage,
                                      iconColor: vault.vault.displayPreferences.color.color.color,
                                      backgroundColor: vault.vault.displayPreferences.color.color
                                          .color
                                          .withAlphaComponent(0.16))
                     },
                     title: vault.vault.name,
                     itemCount: vault.itemCount,
                     isShared: false, // No need to show share indicator
                     isSelected: false,
                     height: 74)

            Spacer()

            CapsuleTextButton(title: #localized("Share this vault"),
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              action: onShareVault)
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal)
        .roundedEditableSection()
    }
}

private extension ShareOrCreateNewVaultView {
    var createNewVaultButton: some View {
        Button(action: onCreateNewVault) {
            Label(title: {
                Text("Create a new vault to share")
                    .foregroundColor(PassColor.textNorm.toColor)
            }, icon: {
                CircleButton(icon: IconProvider.plus,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1)
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 72)
            .padding(.horizontal)
            .roundedEditableSection(borderColor: PassColor.interactionNormMajor2)
        }
    }
}
