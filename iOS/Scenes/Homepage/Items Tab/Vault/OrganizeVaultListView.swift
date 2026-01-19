//
// OrganizeVaultListView.swift
// Proton Pass - Created on 15/01/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Foundation
import Screens
import SwiftUI

struct OrganizeVaultListView: View {
    @ObservedObject var viewModel: EditableVaultListViewModel

    var body: some View {
        VStack(alignment: .leading) {
            topView
            vaultsScrollView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(.default, value: viewModel.hiddenShareIds)
        .background(PassColor.backgroundWeak)
    }

    var topView: some View {
        HStack {
            Button(action: {
                viewModel.updateMode(.view)
            }, label: {
                Text("Cancel")
                    .foregroundStyle(PassColor.interactionNormMajor2)
            })

            Spacer()

            Text("Organize vaults")
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm)

            Spacer()

            Button(action: {
                viewModel.applyVaultsOrganizations()
            }, label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .foregroundStyle(PassColor.interactionNormMajor2)
            })
        }
        .padding()
    }

    var vaultsScrollView: some View {
        LazyVStack(spacing: 0) {
            if case .loaded = viewModel.state {
                if viewModel.visibleVaults.count != viewModel.hiddenShareIds.count {
                    Text("Visible vaults")
                        .fontWeight(.semibold)
                        .foregroundStyle(PassColor.textNorm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                }

                ForEach(viewModel.visibleVaults) { content in
                    vaultRow(for: .precise(content.share, folderId: nil))
                    if viewModel.mode.isView ||
                        (viewModel.mode.isOrganise && !viewModel.isLastVisibleVault(content.share)) {
                        PassDivider()
                    }
                }

                if !viewModel.hiddenShareIds.isEmpty {
                    Text("Hidden vaults")
                        .fontWeight(.semibold)
                        .foregroundStyle(PassColor.textNorm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        .padding(.bottom, 4)
                    // swiftlint:disable:next line_length
                    Text("These vaults will not be accessible and their content won't be available to Search or Autofill.")
                        .foregroundStyle(PassColor.textWeak)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                }

                ForEach(viewModel.hiddenVaults) { content in
                    vaultRow(for: .precise(content.share, folderId: nil))
                    if !viewModel.isLastHiddenVault(content.share) {
                        PassDivider()
                    }
                }
            }
        }
        .padding(.horizontal)
        .scrollViewEmbeded()
    }

    @ViewBuilder
    func vaultRow(for selection: ShareSelection) -> some View {
        if let share = selection.share {
            let vaultRowMode: VaultRowMode = .organise(isHidden: viewModel.hiddenShareIds
                .contains(share.shareId))
            HStack {
                Button(action: {
                    viewModel.hideOrUnhide(share: share)
                }, label: {
                    VaultRow(thumbnail: {
                                 CircleButton(icon: selection.icon,
                                              iconColor: selection.color,
                                              backgroundColor: selection.color.opacity(0.16))
                             },
                             title: selection.title,
                             itemCount: viewModel.itemCount(for: selection),
                             share: share,
                             mode: vaultRowMode,
                             height: 74)
                })
                .buttonStyle(.plain)
            }
        }
    }
}
