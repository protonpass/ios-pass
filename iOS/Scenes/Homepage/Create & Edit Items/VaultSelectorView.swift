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

import Client
import Core
import SwiftUI
import UIComponents

protocol VaultSelectorViewModelDelegate: AnyObject {
    func vaultSelectorViewModelDidSelect(vault: Vault)
}

final class VaultSelectorViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let allVaults: [VaultListUiModel]
    @Published private(set) var selectedVault: Vault

    weak var delegate: VaultSelectorViewModelDelegate?

    init(allVaults: [VaultListUiModel], selectedVault: Vault) {
        self.allVaults = allVaults
        self.selectedVault = selectedVault
    }

    func select(vault: Vault) {
        delegate?.vaultSelectorViewModelDidSelect(vault: vault)
    }
}

struct VaultSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: VaultSelectorViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.allVaults, id: \.hashValue) { vault in
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

                        PassDivider()
                            .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: PassColor.backgroundWeak))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select a vault")
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
