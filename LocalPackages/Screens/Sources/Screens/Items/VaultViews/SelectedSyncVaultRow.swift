//
// SelectedSyncVaultRow.swift
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct SelectedSyncVaultRow: View {
    private let vault: Share?
    let action: () -> Void

    public init(vault: Share?,
                action: @escaping () -> Void) {
        self.vault = vault
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            selectedVault
                .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .roundedEditableSection()
        .padding(.bottom, 10)
    }

    private var selectedVault: some View {
        HStack(spacing: 16) {
            if let vaultContent = vault?.vaultContent {
                VaultThumbnail(vaultContent: vaultContent)
            }

            VStack(alignment: .leading) {
                Text("Default SimpleLogin vault", bundle: .module)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak)

                Text(vault?.vaultContent?.name ?? #localized("None", bundle: .module))
                    .if(vault?.vaultContent?.name == nil) { view in
                        view
                            .italic()
                            .foregroundStyle(PassColor.textWeak)
                    }
                    .foregroundStyle(PassColor.textNorm)
            }
            Spacer()

            Image(uiImage: IconProvider.chevronRight)
                .resizable()
                .scaledToFit()
                .foregroundStyle(PassColor.textWeak)
                .frame(maxHeight: 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: OptionRowHeight.medium.value)
        .contentShape(.rect)
    }
}
