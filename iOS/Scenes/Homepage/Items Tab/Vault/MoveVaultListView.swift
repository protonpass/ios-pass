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

import DesignSystem
import Entities
import Macro
import Screens
import SwiftUI

struct MoveVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MoveVaultListViewModel

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .center) {
                Text("Select a vault")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm.toColor)

                if viewModel.showWarning {
                    // swiftlint:disable:next line_length
                    Label("When moving items between vaults we will preserve up to the last 50 modifications performed to each item",
                          systemImage: "info.circle.fill")
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(PassColor.backgroundNorm.toColor)
                        .cornerRadius(12)

                    Divider()
                        .padding(.top, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.top, 30)

            if viewModel.isFreeUser {
                LimitedVaultOperationsBanner(onUpgrade: { viewModel.upgrade() })
                    .padding([.horizontal, .top])
            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.allVaults, id: \.hashValue) { vault in
                        if let vaultContent = vault.share.vaultContent {
                            vaultRow(for: vault, vaultContent: vaultContent)
                            if vault != viewModel.allVaults.last {
                                PassDivider()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: 16) {
                CapsuleTextButton(title: #localized("Cancel"),
                                  titleColor: PassColor.textWeak,
                                  backgroundColor: PassColor.textDisabled,
                                  height: 44,
                                  action: dismiss.callAsFunction)

                DisablableCapsuleTextButton(title: #localized("Confirm"),
                                            titleColor: PassColor.textInvert,
                                            disableTitleColor: PassColor.textHint,
                                            backgroundColor: PassColor.interactionNormMajor1,
                                            disableBackgroundColor: PassColor.interactionNormMinor1,
                                            disabled: viewModel.selectedVault == nil,
                                            height: 44,
                                            action: { dismiss(); viewModel.doMove() })
            }
            .padding([.bottom, .horizontal])
        }
        .background(PassColor.backgroundWeak.toColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.default, value: viewModel.isFreeUser)
    }

    private func vaultRow(for vault: ShareContent, vaultContent: VaultContent) -> some View {
        Button(action: {
            viewModel.selectedVault = vault
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vault.itemCount,
                     mode: .view(isSelected: viewModel.selectedVault == vault,
                                 isHidden: vault.share.hidden,
                                 action: nil))
        })
        .buttonStyle(.plain)
        .opacityReduced(!vault.share.canEdit)
    }
}
