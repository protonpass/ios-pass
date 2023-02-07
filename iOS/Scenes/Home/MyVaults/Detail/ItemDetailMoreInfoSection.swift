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
import ProtonCore_UIFoundations
import SwiftUI

struct ItemDetailMoreInfoSection: View {
    @State private var isExpanded = false
    let uiModel: ItemDetailMoreInfoSectionUIModel
    let onExpand: () -> Void

    init(itemContent: ItemContent, onExpand: @escaping () -> Void) {
        self.uiModel = .init(itemContent: itemContent)
        self.onExpand = onExpand
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !isExpanded {
                Divider()
            }

            HStack {
                HStack {
                    Label(title: {
                        Text("More info")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textWeak)
                    }, icon: {
                        icon(from: IconProvider.infoCircle)
                    })

                    Spacer()

                    if !isExpanded {
                        Image(uiImage: IconProvider.chevronDown)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16)
                            .foregroundColor(.textWeak)
                    }
                }
            }
            .padding(.bottom, 8)

            if isExpanded {
                Group {
                    let sectionTitleWidth: CGFloat = 100

                    if let lastAutoFilledDate = uiModel.lastAutoFilledDate {
                        HStack(spacing: 20) {
                            Text("Auto-filled:")
                                .fontWeight(.semibold)
                                .frame(width: sectionTitleWidth, alignment: .trailing)
                            Text(lastAutoFilledDate)
                                .fontWeight(.semibold)
                        }
                    }

                    HStack(spacing: 20) {
                        VStack {
                            Text("Modified:")
                                .fontWeight(.semibold)
                                .frame(width: sectionTitleWidth, alignment: .trailing)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(uiModel.modificationCount)
                                .fontWeight(.semibold)
                            Text(uiModel.modificationDate)
                        }
                    }

                    HStack(spacing: 20) {
                        Text("Created:")
                            .fontWeight(.semibold)
                            .frame(width: sectionTitleWidth, alignment: .trailing)
                        Text(uiModel.creationDate)
                            .fontWeight(.semibold)
                    }
                }
                .font(.caption)
                .foregroundColor(.textWeak)
            }

            if !isExpanded {
                Divider()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isExpanded {
                isExpanded = true
                onExpand()
            }
        }
        .animation(.default, value: isExpanded)
    }

    private var moreInfoRow: some View {
        HStack {
            Label(title: {
                Text("More info")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.textWeak)
            }, icon: {
                icon(from: IconProvider.infoCircle)
            })

            Spacer()

            icon(from: IconProvider.chevronDown)
        }
    }

    private func icon(from image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 16)
            .foregroundColor(.textWeak)
    }
}

final class ItemDetailMoreInfoSectionUIModel {
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

        if case .login = itemContent.contentData.type {
            lastAutoFilledDate = fullDateString(item.lastUseTime).capitalizingFirstLetter()
        } else {
            lastAutoFilledDate = nil
        }

        modificationCount = "\(item.revision) time(s)"
        modificationDate = "Last time, \(fullDateString(item.modifyTime))"
        creationDate = fullDateString(item.createTime).capitalizingFirstLetter()
    }
}
