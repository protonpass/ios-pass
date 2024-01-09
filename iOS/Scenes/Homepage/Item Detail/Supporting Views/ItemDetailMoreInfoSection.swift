//
// ItemDetailMoreInfoSection.swift
// Proton Pass - Created on 06/02/2023.
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
import DesignSystem
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreUIFoundations
import SwiftUI

extension ItemContent {
    var lastAutoFilledDate: String? {
        if case .login = contentData.type,
           let lastUseTime = item.lastUseTime,
           lastUseTime != item.createTime {
            lastUseTime.fullDateString.capitalizingFirstLetter()
        } else {
            nil
        }
    }

    var modificationDate: String {
        #localized("Last time, %@", item.modifyTime.fullDateString)
    }

    var creationDate: String {
        item.createTime.fullDateString.capitalizingFirstLetter()
    }
}

extension Int64 {
    var fullDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        let relativeDateFormatter = RelativeDateTimeFormatter()

        let timeInterval = TimeInterval(self)
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateString = dateFormatter.string(from: date)
        let relativeString = relativeDateFormatter.localizedString(for: date, relativeTo: .now)
        return "\(dateString) (\(relativeString))"
    }
}

struct ItemDetailMoreInfoSection: View {
    private let clipboardManager = resolve(\SharedServiceContainer.clipboardManager)
    private let item: ItemContent
    let action: () -> Void

    init(itemContent: ItemContent,
         action: @escaping () -> Void) {
        item = itemContent
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            infoRow(title: "Item ID", infos: item.itemId, icon: IconProvider.infoCircle)
                .textSelection(.enabled)
                .onTapGesture(perform: copyItemId)

            infoRow(title: "Vault ID", infos: item.shareId, icon: IconProvider.infoCircle)
                .textSelection(.enabled)
                .onTapGesture(perform: copyVaultId)

            if let lastAutoFill = item.lastAutoFilledDate {
                infoRow(title: "Last autofill", infos: lastAutoFill, icon: IconProvider.magicWand)
            }

            infoRow(title: "Last Modified", infos: item.modificationDate, icon: IconProvider.pencil)

            infoRow(title: "Created", infos: item.creationDate, icon: IconProvider.bolt)

            CapsuleTextButton(title: "View Item history",
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1,
                              action: action)
                .padding(.horizontal, DesignConstant.sectionPadding)
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
        .padding(.top, 16)
    }
}

private extension ItemDetailMoreInfoSection {
    func infoRow(title: LocalizedStringKey, infos: String, icon: UIImage) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: icon,
                                  color: PassColor.textWeak)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(infos)
                    .font(.footnote)
                    .foregroundColor(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }.padding(.horizontal, DesignConstant.sectionPadding)
    }

    func copyItemId() {
        clipboardManager.copy(text: item.itemId,
                              bannerMessage: #localized("Item ID copied"))
    }

    func copyVaultId() {
        clipboardManager.copy(text: item.shareId,
                              bannerMessage: #localized("Vault ID copied"))
    }
}
