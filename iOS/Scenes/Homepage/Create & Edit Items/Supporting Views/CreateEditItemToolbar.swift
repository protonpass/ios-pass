//
// CreateEditItemToolbar.swift
// Proton Pass - Created on 08/02/2023.
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreateEditItemToolbar: ToolbarContent {
    let saveButtonTitle: String
    let isSaveable: Bool
    let isSaving: Bool
    let canScanDocuments: Bool
    let container: ShareSelectionPayload
    let canChangeVault: Bool
    let itemContentType: ItemContentType
    let shouldUpgrade: Bool
    let isPhone: Bool
    let onSelectVault: () -> Void
    let onGoBack: () -> Void
    let onUpgrade: () -> Void
    let onScan: () -> Void
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: itemContentType.normMajor2Color,
                         backgroundColor: itemContentType.normMinor1Color,
                         accessibilityLabel: "Close",
                         action: onGoBack)
                .animation(.default, value: isSaving)
                .disabled(isSaving)
        }

        if shouldUpgrade {
            ToolbarItem(placement: .topBarTrailing) {
                UpgradeButton(backgroundColor: itemContentType.normMajor1Color,
                              action: onUpgrade)
                    .disabled(isSaving)
            }
        } else {
            ToolbarItem(placement: .principal) {
                Group {
                    if canChangeVault {
                        if container.isFolderSelected {
                            folderButton(folderName: container.title)
                        } else if let vaultContent = container.share.vaultContent {
                            vaultButton(vaultContent: vaultContent)
                        }
                    } else {
                        EmptyView()
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Group {
                    if isSaving {
                        ProgressView()
                    } else {
                        buttons
                    }
                }
                .animation(.default, value: isSaving)
            }
        }
    }
}

private extension CreateEditItemToolbar {
    var buttons: some View {
        HStack {
            if !ProcessInfo.processInfo.isiOSAppOnMac, canScanDocuments {
                switch itemContentType {
                case .creditCard, .note:
                    CircleButton(icon: PassIcon.scanner,
                                 iconColor: itemContentType.normMajor2Color,
                                 backgroundColor: itemContentType.normMinor1Color,
                                 accessibilityLabel: "Scan \(itemContentType == .note ? "document" : "credit card")",
                                 action: onScan)
                default:
                    EmptyView()
                }
            }

            DisablableCapsuleTextButton(title: saveButtonTitle,
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: itemContentType.normMajor1Color,
                                        disableBackgroundColor: itemContentType.normMinor1Color,
                                        disabled: !isSaveable,
                                        action: onSave)
        }
    }

    func vaultButton(vaultContent: VaultContent) -> some View {
        HStack {
            vaultContent.vaultBigIcon
                .resizable()
                .scaledToFit()
                .frame(width: 18)
            Text(vaultContent.name)
            Image(systemName: "chevron.down")
                .resizable()
                .scaledToFit()
                .frame(width: 12)
        }
        .frame(height: 40)
        .foregroundStyle(vaultContent.mainColor)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .background(vaultContent.backgroundColor)
        .clipShape(Capsule())
//        .if(isPhone) { view in
//            view.frame(maxWidth: 150, alignment: .trailing)
//        }
//        .fixedSize(horizontal: false, vertical: false)
        .buttonEmbeded(action: onSelectVault)
    }

    func folderButton(folderName: String) -> some View {
        HStack {
            IconProvider.foldersFilled
                .resizable()
                .foregroundStyle(Color(hex: "#E9A944"))
                .scaledToFit()
                .frame(width: 18)
            Text(folderName)
            Image(systemName: "chevron.down")
                .resizable()
                .scaledToFit()
                .frame(width: 12)
        }
        .frame(height: 40)
        .foregroundStyle(PassColor.textNorm)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .background(PassColor.interactionNormMinor1)
        .clipShape(Capsule())
//        .if(isPhone) { view in
//            view.frame(maxWidth: 150, alignment: .trailing)
//        }
//        .fixedSize(horizontal: false, vertical: false)
        .buttonEmbeded(action: onSelectVault)
    }
}
