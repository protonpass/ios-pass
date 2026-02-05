//
// ItemPathBreadcrumbView.swift
// Proton Pass - Created on 05/02/2026.
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
import ProtonCoreUIFoundations
import SwiftUI

struct ItemPathBreadcrumbView: View {
    let share: Share
    let itemPath: [FolderUiModel]
    @State private var expanded: Bool = false

    var body: some View {
        Button { expanded.toggle() } label: {
            renderedText
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}

private extension ItemPathBreadcrumbView {
    @ViewBuilder
    var renderedText: some View {
        if let vaultContent = share.vaultContent {
            if !expanded, let lastFolder = itemPath.last {
                nonExtendedView(vaultContent: vaultContent, lastFolder: lastFolder)
            } else {
                extendedView(vaultContent: vaultContent)
            }
        }
    }

    func nonExtendedView(vaultContent: VaultContent, lastFolder: FolderUiModel) -> some View {
        HStack(spacing: 4) {
            Label {
                Text(vaultContent.name)
                    .lineLimit(1)
                    .foregroundStyle(PassColor.textWeak)
            } icon: {
                vaultContent.vaultSmallIcon
                    .resizable()
                    .foregroundStyle(vaultContent.mainColor)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }

            if itemPath.count > 1 {
                IconProvider.chevronRight
                    .resizable()
                    .foregroundStyle(PassColor.textWeak)
                    .frame(width: 16, height: 16)
                Text("...")
                    .foregroundStyle(PassColor.textWeak)
            }
            IconProvider.chevronRight
                .resizable()
                .foregroundStyle(PassColor.textWeak)
                .frame(width: 16, height: 16)

            Label {
                Text(lastFolder.content.name)
                    .lineLimit(1)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                IconProvider.foldersFilled
                    .resizable()
                    .foregroundStyle(PassColor.folderIcon)
                    .frame(width: 16, height: 16)
            }
            Spacer()
        }
    }

    func extendedView(vaultContent: VaultContent) -> some View {
        AnyLayout(FlowLayout(spacing: 8)) {
            Label {
                Text(vaultContent.name)
                    .lineLimit(1)
                    .foregroundStyle(PassColor.textWeak)
            } icon: {
                vaultContent.vaultSmallIcon
                    .resizable()
                    .foregroundStyle(vaultContent.mainColor)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            ForEach(itemPath) { folder in
                let isLast = if let last = itemPath.last, last == folder {
                    true
                } else {
                    false
                }
                folderElement(folderName: folder.content.name, isLast: isLast)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func folderElement(folderName: String, isLast: Bool) -> some View {
        HStack(spacing: 4) {
            IconProvider.chevronRight
                .resizable()
                .foregroundStyle(PassColor.textWeak)
                .frame(width: 16, height: 16)
            Label {
                Text(folderName)
                    .fontWeight(isLast ? .bold : .regular)
                    .foregroundStyle(isLast ? PassColor.textNorm : PassColor.textWeak)
            } icon: {
                IconProvider.foldersFilled
                    .resizable()
                    .foregroundStyle(PassColor.folderIcon)
                    .frame(width: 16, height: 16)
            }
        }
    }
}
