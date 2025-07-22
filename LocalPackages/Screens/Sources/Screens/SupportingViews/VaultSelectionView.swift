//
// VaultSelectionView.swift
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
import ProtonCoreUIFoundations
import SwiftUI

public struct VaultSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVault: VaultListUiModel?
    public let vaults: [VaultListUiModel]

    public init(selectedVault: Binding<VaultListUiModel?>, vaults: [VaultListUiModel]) {
        _selectedVault = selectedVault
        self.vaults = vaults
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vaults, id: \.vault.id) { vault in
                        if let vaultContent = vault.vault.vaultContent {
                            let isSelected = vault == selectedVault
                            Button(action: {
                                selectedVault = vault
                                dismiss()
                            }, label: {
                                VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                                         title: vaultContent.name,
                                         itemCount: vault.itemCount,
                                         share: vault.vault,
                                         mode: .view(isSelected: isSelected,
                                                     isHidden: vault.vault.hidden,
                                                     action: nil),
                                         height: 74)
                                    .padding(.horizontal)
                            })
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: selectedVault)
            .navigationTitle(Text("Default SimpleLogin vault", bundle: .module))
        }
    }
}
