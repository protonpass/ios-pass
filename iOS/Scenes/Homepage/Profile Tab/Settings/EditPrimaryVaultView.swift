//
// EditPrimaryVaultView.swift
// Proton Pass - Created on 31/03/2023.
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

struct EditPrimaryVaultView: View {
    @StateObject var viewModel: EditPrimaryVaultViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.allVaults, id: \.vault.shareId) { vault in
                        OptionRow(
                            action: { viewModel.setAsPrimary(vault: vault.vault) },
                            height: .medium,
                            content: {
                                VaultRow(
                                    thumbnail: { VaultThumbnail(vault: vault.vault) },
                                    title: vault.vault.name,
                                    itemCount: vault.itemCount,
                                    isSelected: vault.vault.shareId == viewModel.primaryVault.shareId,
                                    height: 44)
                            })

                        if vault.vault.shareId != viewModel.allVaults.last?.vault.shareId {
                            PassDivider()
                        }
                    }

                    Spacer()
                }
                .roundedEditableSection()
                .padding([.top, .horizontal])
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(viewModel.isLoading)
            .background(Color(uiColor: PassColor.backgroundWeak))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavigationTitleWithHandle(title: "Primary vault")
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
