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
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import Screens
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
                if case let .vault(vault) = info.shareElement, let vaultContent = vault.vaultContent {
                    vaultInfo(vaultContent: vaultContent, itemsCount: info.itemsNum)
                } else if case let .item(item, _) = info.shareElement {
                    itemInfo(infos: item)
                }
                permissionInfo(infos: info)
            } else if let info = viewModel.infos.first {
                if case let .vault(vault) = info.shareElement, let vaultContent = vault.vaultContent {
                    vaultInfo(vaultContent: vaultContent, itemsCount: info.itemsNum)
                } else if case let .item(item, _) = info.shareElement {
                    itemInfo(infos: item)
                }
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
    func vaultInfo(vaultContent: VaultContent, itemsCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Vault")
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(height: 20)
            VaultRow(thumbnail: {
                         CircleButton(icon: vaultContent.vaultBigIcon,
                                      iconColor: vaultContent.mainColor,
                                      backgroundColor: vaultContent.backgroundColor)
                     },
                     title: vaultContent.name,
                     itemCount: itemsCount,
                     height: 60)
        }
    }

    func itemInfo(infos: ItemContent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Item")
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(height: 20)

            GeneralItemRow(thumbnailView: {
                               ItemSquircleThumbnail(data: infos.thumbnailData(),
                                                     pinned: false)
                           },
                           title: infos.title,
                           description: infos.description)
                .frame(height: 60)
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
            VStack(alignment: .leading, spacing: 15) {
                Text(infos.role.title(managerAsAdmin: viewModel.managerAsAdmin))
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(infos.role.description(isItemSharing: infos.shareElement.isItem))
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(PassColor.textWeak.toColor,
                              lineWidth: 1))
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
                                    Text(info.role.title(managerAsAdmin: viewModel.managerAsAdmin))
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
        if let info = viewModel.infos.first {
            ToolbarItem(placement: .topBarTrailing) {
                DisablableCapsuleTextButton(title: info
                    .isItem ? #localized("Share Item") : #localized("Share Vault"),
                    titleColor: PassColor.textInvert,
                    disableTitleColor: PassColor.textHint,
                    backgroundColor: PassColor.interactionNormMajor1,
                    disableBackgroundColor: PassColor.interactionNormMinor1,
                    disabled: false,
                    action: { viewModel.sendInvite() })
            }
        }
    }
}

#Preview("SharingSummaryView Preview") {
    SharingSummaryView()
}

private extension ItemContent {
    var title: String { name }

    var description: String {
        switch contentData {
        case let .login(data):
            data.authIdentifier
        case .alias:
            aliasEmail ?? ""
        case let .creditCard(data):
            data.number.toMaskedCreditCardNumber()
        case .note:
            String(note.prefix(50))
        case let .identity(data):
            data.fullName.concatenateWith(data.email, separator: " / ")
        case let .wifi(data):
            data.ssid
        case .custom, .sshKey:
            firstTextCustomFieldValue ?? ""
        }
    }
}
