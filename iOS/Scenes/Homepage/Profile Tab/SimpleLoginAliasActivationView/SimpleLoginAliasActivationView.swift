//
//
// SimpleLoginAliasActivationView.swift
// Proton Pass - Created on 05/08/2024.
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
//

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct SimpleLoginAliasActivationView: View {
    @StateObject private var viewModel = SimpleLoginAliasActivationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showVaultSelectionSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            SelectedSyncVaultRow(vault: viewModel.selectedVault?.vault) {
                showVaultSelectionSheet.toggle()
            }

            Text("SimpleLogin aliases will be imported into this vault.")
                .font(.footnote)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .navigationTitle("Sync aliases")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .sheet(isPresented: $showVaultSelectionSheet) {
            VaultSelectionView(selectedVault: $viewModel.selectedVault,
                               vaults: viewModel.vaults)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .showSpinner(viewModel.loading)
        .navigationStackEmbeded()
    }
}

private extension SimpleLoginAliasActivationView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor1,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Confirm"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canActiveSync,
                                        height: 44) {
                Task {
                    if await viewModel.activateSync() {
                        dismiss()
                    }
                }
            }
        }
    }
}
