//
// EditSpotlightVaultsView.swift
// Proton Pass - Created on 01/02/2024.
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
import FactoryKit
import Screens
import SwiftUI

struct EditSpotlightVaultsView: View {
    @StateObject private var viewModel = EditSpotlightVaultsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.allVaults) { vault in
                if let vaultContent = vault.vault.vaultContent {
                    view(for: vault, vaultContent: vaultContent)
                    PassDivider()
                        .padding(.horizontal)
                }
            }
        }
        .scrollViewEmbeded()
        .navigationBarTitleDisplayMode(.inline)
        .background(PassColor.backgroundWeak.toColor)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Selected vaults")
                    .navigationTitleText()
            }
        }
        .navigationStackEmbeded()
    }

    @MainActor
    private func view(for vault: VaultListUiModel, vaultContent: VaultContent) -> some View {
        Button(action: {
            viewModel.toggleSelection(vault: vault.vault)
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vault.itemCount,
                     mode: .view(isSelected: viewModel.isSelected(vault: vault.vault), action: nil),
                     height: 74)
                .padding(.horizontal)
        })
        .buttonStyle(.plain)
    }
}
