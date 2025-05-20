//
// ItemDetailHistorySection.swift
// Proton Pass - Created on 09/01/2024.
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

import Client
import DesignSystem
import Entities
import FactoryKit
import Foundation
import Macro
import ProtonCoreUIFoundations
import Screens
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
        item.modifyTime.fullDateString
    }

    var creationDate: String {
        item.createTime.fullDateString.capitalizingFirstLetter()
    }

    var revisionDate: String {
        item.revisionTime.fullDateString
    }

    var shortRevisionDate: String {
        item.revisionTime.shortDateString
    }
}

struct ItemDetailHistorySection: View {
    private let item: ItemContent
    let action: (() -> Void)?

    init(itemContent: ItemContent,
         action: (() -> Void)?) {
        item = itemContent
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            if let lastAutoFill = item.lastAutoFilledDate {
                infoRow(title: "Last autofill", infos: lastAutoFill, icon: IconProvider.magicWand)
            }

            infoRow(title: "Last modified", infos: item.modificationDate, icon: IconProvider.pencil)

            infoRow(title: "Created", infos: item.creationDate, icon: IconProvider.bolt)

            if let action {
                CapsuleTextButton(title: #localized("View item history"),
                                  titleColor: item.contentData.type.normMajor2Color,
                                  backgroundColor: item.contentData.type.normMinor1Color,
                                  action: action)
                    .padding(.horizontal, DesignConstant.sectionPadding)
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
        .padding(.top, DesignConstant.sectionPadding)
    }
}

private extension ItemDetailHistorySection {
    func infoRow(title: LocalizedStringKey, infos: String, icon: UIImage) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: icon,
                                  color: PassColor.textWeak)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(infos)
                    .font(.footnote)
                    .foregroundStyle(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }.padding(.horizontal, DesignConstant.sectionPadding)
    }
}
