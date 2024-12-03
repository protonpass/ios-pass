//
// VaultSelectorView.swift
// Proton Pass - Created on 12/04/2023.
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
import Factory
import Screens
import SwiftUI

struct VaultSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVault: Share
    let isFreeUser: Bool
    let onUpgrade: () -> Void

    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)

    private var vaults: [VaultContentUiModel] {
        vaultsManager
            .getAllEditableVaultContents()
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isFreeUser {
                    LimitedVaultOperationsBanner(onUpgrade: onUpgrade)
                        .padding([.horizontal, .top])
                }

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(vaults) { vault in
                            if let vaultContent = vault.vault.vaultContent {
                                view(for: vault, vaultContent: vaultContent)
                            }
                            if vault != vaults.last {
                                PassDivider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(PassColor.backgroundWeak.toColor)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select a vault")
                        .navigationTitleText()
                }
            }
        }
    }

    private func view(for vaultInfos: VaultContentUiModel, vaultContent: VaultContent) -> some View {
        Button(action: {
            selectedVault = vaultInfos.vault
            dismiss()
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vaultInfos.itemCount,
                     isShared: vaultInfos.vault.shared,
                     isSelected: selectedVault == vaultInfos.vault,
                     height: 74)
                .padding(.horizontal)
        })
        .buttonStyle(.plain)
    }
}
