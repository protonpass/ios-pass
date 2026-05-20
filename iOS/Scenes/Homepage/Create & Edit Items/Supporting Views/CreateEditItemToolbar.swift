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
    let onSelectContainer: () -> Void
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
                containerButton
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

    @ViewBuilder
    var containerButton: some View {
        if canChangeVault, let containerType {
            if #available(iOS 26.0, *) {
                Button(action: onSelectContainer) {
                    containerButtonContent(containerType)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(containerType.background), in: .capsule)
                .buttonStyle(.glass)
            } else {
                Button(action: onSelectContainer) {
                    containerButtonContent(containerType)
                        .background(containerType.background)
                        .clipShape(.capsule)
                }
            }
        }
    }

    func containerButtonContent(_ containerType: ContainerType) -> some View {
        HStack {
            containerType.icon
                .scaledToFit()
                .frame(width: 18)
            Text(containerType.title)
            Image(systemName: "chevron.down")
                .resizable()
                .scaledToFit()
                .frame(width: 12)
        }
        .frame(height: 40)
        .foregroundStyle(containerType.foreground)
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var containerType: ContainerType? {
        if container.isFolderSelected {
            .folder(container.title)
        } else if let vaultContent = container.share.vaultContent {
            .vault(vaultContent)
        } else {
            nil
        }
    }
}

private enum ContainerType {
    case folder(String)
    case vault(VaultContent)

    @ViewBuilder
    var icon: some View {
        switch self {
        case .folder:
            IconProvider.foldersFilled
                .resizable()
                .foregroundStyle(PassColor.folderIcon)
        case let .vault(content):
            content.vaultBigIcon
                .resizable()
        }
    }

    var title: String {
        switch self {
        case let .folder(name): name
        case let .vault(content): content.name
        }
    }

    var foreground: Color {
        switch self {
        case .folder:
            PassColor.textNorm
        case let .vault(content):
            content.mainColor
        }
    }

    var background: Color {
        switch self {
        case .folder:
            PassColor.interactionNormMinor1
        case let .vault(content):
            content.backgroundColor
        }
    }
}
