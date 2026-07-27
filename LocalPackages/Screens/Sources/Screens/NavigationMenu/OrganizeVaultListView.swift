//
// OrganizeVaultListView.swift
// Proton Pass - Created on 27/07/2026.
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
import SwiftUI

struct OrganizeVaultListView: View {
    let viewModel: NavigationMenuViewModel

    var body: some View {
        VStack(alignment: .leading) {
            topView
            vaultsScrollView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(.default, value: viewModel.hiddenShareIds)
        .background(PassColor.backgroundWeak)
        .showSpinner(viewModel.loading)
    }

    var topView: some View {
        HStack {
            Button(action: {
                viewModel.updateMode(.view)
            }, label: {
                Text("Cancel", bundle: .module)
                    .foregroundStyle(PassColor.interactionNormMajor2)
            })

            Spacer()

            Text("Organize vaults", bundle: .module)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm)

            Spacer()

            Button(action: {
                viewModel.applyVaultsOrganizations()
            }, label: {
                Text("Done", bundle: .module)
                    .fontWeight(.semibold)
                    .foregroundStyle(PassColor.interactionNormMajor2)
            })
        }
        .padding()
    }

    var vaultsScrollView: some View {
        LazyVStack(spacing: 0) {
            if case .loaded = viewModel.state {
                Text("Visible vaults", bundle: .module)
                    .fontWeight(.semibold)
                    .foregroundStyle(PassColor.textNorm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)

                ForEach(viewModel.visibleVaults) { content in
                    vaultRow(for: .precise(.init(share: content.share, folder: nil)))
                    if !viewModel.isLastVisibleVault(content.share) {
                        PassDivider()
                    }
                }

                if !viewModel.hiddenShareIds.isEmpty {
                    Text("Hidden vaults", bundle: .module)
                        .fontWeight(.semibold)
                        .foregroundStyle(PassColor.textNorm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        .padding(.bottom, 4)
                    // swiftlint:disable:next line_length
                    Text("These vaults will not be accessible and their content won't be available to Search or Autofill.",
                         bundle: .module)
                        .foregroundStyle(PassColor.textWeak)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                }

                ForEach(viewModel.hiddenVaults) { content in
                    vaultRow(for: .precise(.init(share: content.share, folder: nil)))
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
            let mode: VaultRowMode = .organise(isHidden: viewModel.hiddenShareIds.contains(share.shareId))
            MenuVaultSelectionRow(selection: selection,
                                  itemCount: viewModel.itemCount(for: selection),
                                  mode: mode) {
                viewModel.hideOrUnhide(share: share)
            }
        }
    }
}
