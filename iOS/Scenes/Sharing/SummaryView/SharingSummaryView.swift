//
//
// SharingSummaryView.swift
// Proton Pass - Created on 20/07/2023.
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
//

import Core
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct SharingSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SharingSummaryViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Review and share")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
            if viewModel.hasSingleInvite, let info = viewModel.infos.first {
                emailInfo(infos: info)
                vaultInfo(infos: info)
                permissionInfo(infos: info)
            } else if let info = viewModel.infos.first {
                vaultInfo(infos: info)
                infosList
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignConstant.sectionPadding)
        .navigationBarTitleDisplayMode(.inline)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .showSpinner(viewModel.sendingInvite)
        .alert("Error occurred",
               isPresented: $viewModel.showContactSupportAlert,
               actions: { Button(role: .cancel, label: { Text("OK") }) },
               message: { Text("Please contact us to investigate the issue") })
    }
}

private extension SharingSummaryView {
    func vaultInfo(infos: SharingInfos) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Vault")
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(height: 20)
            VaultRow(thumbnail: {
                         CircleButton(icon: infos.displayPreferences.icon.icon.bigImage,
                                      iconColor: infos.displayPreferences.color.color.color,
                                      backgroundColor: infos.displayPreferences.color.color.color
                                          .withAlphaComponent(0.16))
                     },
                     title: infos.vaultName,
                     itemCount: infos.itemsNum,
                     isShared: infos.shared,
                     isSelected: false,
                     height: 60)
        }
    }
}

private extension SharingSummaryView {
    func emailInfo(infos: SharingInfos) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Share with")
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(height: 20)
            HStack(spacing: DesignConstant.sectionPadding) {
                SquircleThumbnail(data: .initials(infos.email.initials()),
                                  tintColor: ItemType.login.tintColor,
                                  backgroundColor: ItemType.login.backgroundColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(infos.email)
                        .foregroundStyle(PassColor.textNorm.toColor)
                }
            }
            .frame(height: 60)
        }
    }
}

private extension SharingSummaryView {
    func permissionInfo(infos: SharingInfos) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Access level")
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(height: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(infos.role.title)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(infos.role.description)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(PassColor.textWeak.toColor,
                                      lineWidth: 1))
            }
        }
    }
}

private extension SharingSummaryView {
    var infosList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Share with")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(height: 20)

                LazyVStack {
                    ForEach(viewModel.infos) { info in
                        HStack(spacing: DesignConstant.sectionPadding) {
                            SquircleThumbnail(data: .initials(info.email.initials()),
                                              tintColor: ItemType.login.tintColor,
                                              backgroundColor: ItemType.login.backgroundColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(info.email)
                                    .foregroundStyle(PassColor.textNorm.toColor)
                                HStack {
                                    Text(info.role.title)
                                        .foregroundStyle(PassColor.textWeak.toColor)
                                }
                            }

                            Spacer()
                        }.padding(8)
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
    }
}

private extension SharingSummaryView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Go back",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Share Vault"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: false,
                                        action: { viewModel.sendInvite() })
        }
    }
}

#Preview("SharingSummaryView Preview") {
    SharingSummaryView()
}
