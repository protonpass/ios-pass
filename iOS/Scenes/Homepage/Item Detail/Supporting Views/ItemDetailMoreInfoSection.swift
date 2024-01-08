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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ItemDetailMoreInfoSection: View {
    private let clipboardManager = resolve(\SharedServiceContainer.clipboardManager)
    @Binding var isExpanded: Bool
    private let uiModel: ItemDetailMoreInfoSectionUIModel

    init(isExpanded: Binding<Bool>,
         itemContent: ItemContent) {
        _isExpanded = isExpanded
        uiModel = .init(itemContent: itemContent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack {
                    Label(title: {
                        Text("More info")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(uiColor: PassColor.textWeak))
                    }, icon: {
                        icon(from: IconProvider.infoCircle)
                    })

                    Spacer()

                    if isExpanded {
                        icon(from: IconProvider.chevronUp)
                    } else {
                        icon(from: IconProvider.chevronDown)
                    }
                }
            }

            if isExpanded {
                VStack(alignment: .leading) {
                    HStack {
                        title(#localized("Item ID") + ":")
                        Text(uiModel.itemId)
                            .textSelection(.enabled)
                            .onTapGesture(perform: copyItemId)
                    }

                    HStack {
                        title(#localized("Vault ID") + ":")
                        Text(uiModel.vaultId)
                            .textSelection(.enabled)
                            .onTapGesture(perform: copyVaultId)
                    }

                    if let lastAutoFilledDate = uiModel.lastAutoFilledDate {
                        HStack {
                            title(#localized("Auto-filled:"))
                            Text(lastAutoFilledDate)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }

                    HStack {
                        title(#localized("Modified:"))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(uiModel.modificationCount)
                                .fontWeight(.semibold)
                            Text(uiModel.modificationDate)
                        }
                    }

                    HStack {
                        title(#localized("Created:"))
                        Text(uiModel.creationDate)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                .font(.caption)
                .foregroundColor(Color(uiColor: PassColor.textWeak))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isExpanded.toggle() }
        .animation(.default, value: isExpanded)
    }

    private func icon(from image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 16)
            .foregroundColor(Color(uiColor: PassColor.textWeak))
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .fontWeight(.semibold)
            .frame(width: 100, alignment: .trailing)
            .frame(maxHeight: .infinity, alignment: .topTrailing)
    }
}

private extension ItemDetailMoreInfoSection {
    func copyItemId() {
        clipboardManager.copy(text: uiModel.itemId,
                              bannerMessage: #localized("Item ID copied"))
    }

    func copyVaultId() {
        clipboardManager.copy(text: uiModel.vaultId,
                              bannerMessage: #localized("Vault ID copied"))
    }
}

private struct ItemDetailMoreInfoSectionUIModel {
    let itemId: String
    let vaultId: String
    let lastAutoFilledDate: String?
    let modificationCount: String
    let modificationDate: String
    let creationDate: String

    init(itemContent: ItemContent) {
        itemId = itemContent.itemId
        vaultId = itemContent.shareId

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true

        let relativeDateFormatter = RelativeDateTimeFormatter()

        let now = Date()

        let fullDateString: (Int64) -> String = { timeInterval in
            let timeInterval = TimeInterval(timeInterval)
            let date = Date(timeIntervalSince1970: timeInterval)
            let dateString = dateFormatter.string(from: date)
            let relativeString = relativeDateFormatter.localizedString(for: date, relativeTo: now)
            return "\(dateString) (\(relativeString))"
        }

        let item = itemContent.item

        if case .login = itemContent.contentData.type,
           let lastUseTime = item.lastUseTime,
           lastUseTime != item.createTime {
            lastAutoFilledDate = fullDateString(lastUseTime).capitalizingFirstLetter()
        } else {
            lastAutoFilledDate = nil
        }

        modificationCount = #localized("%lld time(s)", item.revision)
        modificationDate = #localized("Last time, %@", fullDateString(item.modifyTime))
        creationDate = fullDateString(item.createTime).capitalizingFirstLetter()
    }
}
