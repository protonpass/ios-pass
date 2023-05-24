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

import SwiftUI
import UIComponents

struct VaultSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: VaultSelectorViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.onlyPrimaryVaultIsAllowed {
                        upgradeMessage
                    }
                    ForEach(viewModel.allVaults, id: \.hashValue) { vault in
                        view(for: vault)
                        PassDivider()
                            .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: PassColor.backgroundWeak))
            .animation(.default, value: viewModel.onlyPrimaryVaultIsAllowed)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select a vault")
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func view(for vault: VaultListUiModel) -> some View {
        Button(action: {
            viewModel.select(vault: vault.vault)
            dismiss()
        }, label: {
            VaultRow(
                thumbnail: { VaultThumbnail(vault: vault.vault) },
                title: vault.vault.name,
                itemCount: vault.itemCount,
                isSelected: vault.vault.shareId == viewModel.selectedVault.shareId,
                height: 74)
            .padding(.horizontal)
        })
        .buttonStyle(.plain)
        .opacityReduced(viewModel.onlyPrimaryVaultIsAllowed && !vault.vault.isPrimary)
    }

    private var upgradeMessage: some View {
        ZStack {
            Text("To interact with other vaults, you need to upgrade your account.")
                .foregroundColor(Color(uiColor: PassColor.textNorm)) +
            Text(" ") +
            Text("Upgrade now")
                .underline(color: Color(uiColor: PassColor.interactionNormMajor1))
                .foregroundColor(Color(uiColor: PassColor.interactionNormMajor1))
        }
        .padding()
        .background(Color(uiColor: PassColor.interactionNormMinor1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: viewModel.upgrade)
    }
}
