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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ItemDetailMoreInfoSection: View {
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

private struct ItemDetailMoreInfoSectionUIModel {
    let lastAutoFilledDate: String?
    let modificationCount: String
    let modificationDate: String
    let creationDate: String

    init(itemContent: ItemContent) {
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
