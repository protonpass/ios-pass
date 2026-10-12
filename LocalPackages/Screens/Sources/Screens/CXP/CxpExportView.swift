//
// CxpExportView.swift
// Proton Pass - Created on 10/08/2026.
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct CxpExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CxpExportViewModel()
    @State private var password = ""
    @State private var showPasswordTextAlert = true

    public init() {}

    public var body: some View {
        if viewModel.passwordVerified {
            mainContent
        } else {
            PassColor.backgroundNorm
                .ignoresSafeArea()
                .showSpinner(viewModel.verifyingPassword)
                .alert(LocalizedStringResource("Enter your password", bundle: .module),
                       isPresented: $showPasswordTextAlert,
                       actions: {
                           SecureField(LocalizedStringResource("Password", bundle: .module),
                                       text: $password)

                           Button(LocalizedStringResource("Confirm", bundle: .module),
                                  action: { viewModel.verify(password: password) })

                           cancelButton
                       },
                       message: {
                           if viewModel.isSSOUser {
                               Text("Please confirm your backup password in order to export data to another app",
                                    bundle: .module)
                           } else {
                               Text("Please confirm your password in order to export data to another app",
                                    bundle: .module)
                           }
                       })
                .alert(LocalizedStringResource("Error occurred", bundle: .module),
                       isPresented: $viewModel.passwordVerificationErrorMessage.mappedToBool(),
                       actions: {
                           Button(LocalizedStringResource("Retry", bundle: .module),
                                  action: {
                                      password = ""
                                      showPasswordTextAlert = true
                                  })

                           cancelButton
                       },
                       message: {
                           if let message = viewModel.passwordVerificationErrorMessage {
                               Text(verbatim: message)
                           }
                       })
        }
    }
}

private extension CxpExportView {
    var cancelButton: some View {
        Button(LocalizedStringResource("Cancel", bundle: .module),
               role: .cancel,
               action: dismiss.callAsFunction)
    }

    var mainContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.vaults) { vault in
                if let vaultContent = vault.share.vaultContent {
                    row(for: vault, vaultContent: vaultContent)

                    if vault.id != viewModel.vaults.last?.id {
                        PassDivider()
                    }
                }
            }
        }
        .padding(.horizontal)
        .scrollViewEmbeded()
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .fullSheetBackground()
        .navigationStackEmbeded()
        .showSpinner(viewModel.exporting)
        .onChange(of: viewModel.exported) { _, newValue in
            if newValue {
                dismiss()
            }
        }
        .alert(LocalizedStringResource("Error occurred", bundle: .module),
               isPresented: $viewModel.exportErrorMessage.mappedToBool(),
               actions: {
                   Button(LocalizedStringResource("Close", bundle: .module),
                          role: .cancel,
                          action: {})
               },
               message: {
                   if let message = viewModel.exportErrorMessage {
                       Text(verbatim: message)
                   }
               })
    }

    func row(for vault: ShareContent, vaultContent: VaultContent) -> some View {
        let isSelected = viewModel.isSelected(vault.share)
        return HStack {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vault.itemCount,
                     mode: .view(isSelected: false, isHidden: vault.share.hidden, action: nil),
                     height: 74)

            if isSelected {
                IconProvider.checkmark
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 16)
                    .foregroundStyle(PassColor.interactionNormMajor2)
            }
        }
        .animation(.default, value: isSelected)
        .opacity(vault.exportable ? 1 : 0.5)
        .buttonEmbeded {
            viewModel.toggleSelection(vault)
        }
        .disabled(!vault.exportable)
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .principal) {
            Text(verbatim: #localized("Export vaults (%1$lld/%2$lld)",
                                      bundle: .module,
                                      viewModel.selectedCount,
                                      viewModel.vaults.count))
                .navigationTitleText()
        }

        ToolbarItem(placement: .topBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Continue", bundle: .module),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: viewModel.continueDisabled,
                                        action: viewModel.startExporting)
        }
    }
}
