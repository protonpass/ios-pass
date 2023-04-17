//
// SettingsView.swift
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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        if UIDevice.current.isIpad {
            realBody
                .theme(viewModel.selectedTheme)
        } else {
            NavigationView {
                realBody
            }
            .navigationViewStyle(.stack)
            .theme(viewModel.selectedTheme)
        }
    }

    private var realBody: some View {
        ScrollView {
            VStack(spacing: kItemDetailSectionPadding) {
                untitledSection
                clipboardSection
                    .padding(.vertical)
                if let primaryVault = viewModel.vaultsManager.getPrimaryVault() {
                    primaryVaultSection(vault: primaryVault)
                }
                applicationSection
                    .padding(.top)
            }
            .padding()
        }
        .itemDetailBackground(theme: viewModel.selectedTheme)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Settings")
        .navigationBarBackButtonHidden()
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: UIDevice.current.isIpad ? IconProvider.chevronLeft : IconProvider.chevronDown,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: viewModel.goBack)
        }
    }

    private var untitledSection: some View {
        VStack(spacing: 0) {
            OptionRow(action: viewModel.editDefaultBrowser,
                      title: "Default browser",
                      height: .tall,
                      content: { Text(viewModel.selectedBrowser.description) },
                      trailing: { ChevronRight() })

            PassSectionDivider()

            OptionRow(
                action: viewModel.editTheme,
                title: "Theme",
                height: .tall,
                content: {
                    Label(title: {
                        Text(viewModel.selectedTheme.description)
                    }, icon: {
                        Image(uiImage: viewModel.selectedTheme.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    })
                },
                trailing: { ChevronRight() })
        }
        .roundedEditableSection()
    }

    private var clipboardSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            Text("Clipboard")
                .sectionHeaderText()
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                OptionRow(action: viewModel.editClipboardExpiration,
                          title: "Clear clipboard",
                          height: .tall,
                          content: { Text(viewModel.selectedClipboardExpiration.description) },
                          trailing: { ChevronRight() })

                PassSectionDivider()

                OptionRow(height: .tall) {
                    Toggle(isOn: $viewModel.shareClipboard) {
                        Text("Share clipboard between devices")
                    }
                    .tint(Color(uiColor: PassColor.interactionNorm))
                }
            }
            .roundedEditableSection()
        }
    }

    private func primaryVaultSection(vault: Vault) -> some View {
        VStack(spacing: 0) {
            Text("Vaults")
                .sectionHeaderText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, kItemDetailSectionPadding)

            OptionRow(action: { viewModel.edit(primaryVault: vault) },
                      title: "Primary vault",
                      height: .tall,
                      content: { Text(vault.name) },
                      leading: { VaultThumbnail(vault: vault) },
                      trailing: { ChevronRight() })
            .roundedEditableSection()

            Text("You can not delete a primary vault")
                .sectionTitleText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, kItemDetailSectionPadding / 2)
        }
    }

    private var applicationSection: some View {
        VStack(spacing: 0) {
            Text("Application")
                .sectionHeaderText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, kItemDetailSectionPadding)

            VStack(spacing: 0) {
                TextOptionRow(title: "View logs", action: viewModel.viewLogs)

                PassSectionDivider()

                OptionRow(
                    action: viewModel.forceSync,
                    height: .medium,
                    content: {
                        Text("Force synchronization")
                            .foregroundColor(Color(uiColor: PassColor.interactionNormMajor2))
                    },
                    trailing: {
                        CircleButton(icon: IconProvider.arrowRotateRight,
                                     iconColor: PassColor.interactionNormMajor2,
                                     backgroundColor: PassColor.interactionNormMinor1)
                    })
            }
            .roundedEditableSection()

            Text("Download all your items again to make sure you are in sync")
                .sectionTitleText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, kItemDetailSectionPadding / 2)
        }
    }
}
