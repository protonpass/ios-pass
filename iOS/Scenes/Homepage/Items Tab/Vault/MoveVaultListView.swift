//
// MoveVaultListView.swift
// Proton Pass - Created on 29/03/2023.
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
import SwiftUI
import UIComponents

struct MoveVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MoveVaultListViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Handle()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 5)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.allVaults, id: \.hashValue) { vault in
                        if vault != viewModel.currentVault {
                            vaultRow(for: vault)
                            if vault != viewModel.allVaults.last {
                                PassDivider()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: 16) {
                CapsuleTextButton(title: "Cancel",
                                  titleColor: PassColor.textWeak,
                                  backgroundColor: PassColor.textDisabled,
                                  height: 44,
                                  action: dismiss.callAsFunction)

                DisablableCapsuleTextButton(title: "Confirm",
                                            titleColor: PassColor.textInvert,
                                            backgroundColor: PassColor.interactionNormMajor1,
                                            disableBackgroundColor: PassColor.interactionNormMinor1,
                                            disabled: viewModel.selectedVault == nil,
                                            height: 44,
                                            action: { dismiss(); viewModel.confirm() })
            }
            .padding([.bottom, .horizontal])
        }
        .background(Color(uiColor: PassColor.backgroundWeak))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func vaultRow(for vault: VaultListUiModel) -> some View {
        Button(action: {
            viewModel.selectedVault = vault
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vault: vault.vault) },
                     title: vault.vault.name,
                     itemCount: vault.itemCount,
                     isSelected: viewModel.selectedVault == vault)
        })
        .buttonStyle(.plain)
    }
}
