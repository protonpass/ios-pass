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
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

@MainActor
struct ShareOrCreateNewVaultView: View {
    private let viewModel: ShareOrCreateNewVaultViewModel

    init(vault: VaultListUiModel, itemContent: ItemContent) {
        viewModel = .init(vault: vault, itemContent: itemContent)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Share")
                .font(.body.bold())
                .foregroundColor(PassColor.textNorm.toColor)

            Text("Use vaults to share this item with another person")
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textWeak.toColor)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            currentVault

            createNewVaultButton
                .padding(.vertical, 12)

            Text("The item will be moved to the new vault")
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textWeak.toColor)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 44)
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
        .background(PassColor.backgroundNorm.toColor)
    }
}

private extension ShareOrCreateNewVaultView {
    var currentVault: some View {
        HStack {
            let vault = viewModel.vault
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
                              action: { viewModel.shareVault() })
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal)
        .roundedEditableSection()
    }
}

private extension ShareOrCreateNewVaultView {
    var createNewVaultButton: some View {
        Button { viewModel.createNewVault() } label: {
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
