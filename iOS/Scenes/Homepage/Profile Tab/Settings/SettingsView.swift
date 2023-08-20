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

// Localized
struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        if viewModel.isShownAsSheet {
            NavigationView {
                realBody
            }
            .navigationViewStyle(.stack)
            .theme(viewModel.selectedTheme)
        } else {
            realBody
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
                        .padding(.bottom)
                }

                logsSection

                applicationSection
                    .padding(.top)
            }
            .padding()
            .showSpinner(viewModel.loading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Settings")
        .navigationBarBackButtonHidden()
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(uiColor: PassColor.backgroundNorm))
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: viewModel.isShownAsSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: viewModel.goBack)
        }
    }

    private var untitledSection: some View {
        VStack(spacing: 0) {
            if !ProcessInfo.processInfo.isiOSAppOnMac {
                OptionRow(action: viewModel.editDefaultBrowser,
                          title: "Default browser",
                          height: .tall,
                          content: {
                              Text(viewModel.selectedBrowser.description)
                                  .foregroundColor(Color(uiColor: PassColor.textNorm))
                          },
                          trailing: { ChevronRight() })

                PassSectionDivider()
            }

            OptionRow(action: viewModel.editTheme,
                      title: "Theme".localized,
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
                          .foregroundColor(Color(uiColor: PassColor.textNorm))
                      },
                      trailing: { ChevronRight() })

            PassSectionDivider()

            OptionRow(height: .tall) {
                Toggle(isOn: $viewModel.displayFavIcons) {
                    Text("Show website thumbnails")
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
                }
                .tint(Color(uiColor: PassColor.interactionNorm))
            }
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
                          title: "Clear clipboard".localized,
                          height: .tall,
                          content: {
                              Text(viewModel.selectedClipboardExpiration.description)
                                  .foregroundColor(Color(uiColor: PassColor.textNorm))
                          },
                          trailing: { ChevronRight() })

                PassSectionDivider()

                OptionRow(height: .tall) {
                    Toggle(isOn: $viewModel.shareClipboard) {
                        Text("Share clipboard between devices")
                            .foregroundColor(Color(uiColor: PassColor.textNorm))
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
                      title: "Primary vault".localized,
                      height: .tall,
                      content: { Text(vault.name).foregroundColor(Color(uiColor: PassColor.textNorm)) },
                      leading: { VaultThumbnail(vault: vault) },
                      trailing: { ChevronRight() })
                .roundedEditableSection()

            Text("You can not delete a primary vault")
                .sectionTitleText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, kItemDetailSectionPadding / 2)
        }
    }

    private var logsSection: some View {
        VStack(spacing: 0) {
            Text("Logs")
                .sectionHeaderText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, kItemDetailSectionPadding)

            VStack(spacing: 0) {
                TextOptionRow(title: PassModule.hostApp.logTitle,
                              action: viewModel.viewHostAppLogs)

                PassSectionDivider()

                TextOptionRow(title: PassModule.autoFillExtension.logTitle,
                              action: viewModel.viewAutoFillExensionLogs)
            }
            .roundedEditableSection()

            OptionRow(action: viewModel.clearLogs,
                      height: .medium,
                      content: {
                          Text("Clear all logs")
                              .foregroundColor(Color(uiColor: PassColor.interactionNormMajor2))
                      },
                      trailing: {
                          CircleButton(icon: IconProvider.trash,
                                       iconColor: PassColor.interactionNormMajor2,
                                       backgroundColor: PassColor.interactionNormMinor1)
                      })
                      .roundedEditableSection()
                      .padding(.top, kItemDetailSectionPadding / 2)
        }
    }

    private var applicationSection: some View {
        VStack(spacing: 0) {
            Text("Application")
                .sectionHeaderText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, kItemDetailSectionPadding)

            OptionRow(action: viewModel.forceSync,
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
                      .roundedEditableSection()

            Text("Download all your items again to make sure you are in sync")
                .sectionTitleText()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, kItemDetailSectionPadding / 2)
        }
    }
}
