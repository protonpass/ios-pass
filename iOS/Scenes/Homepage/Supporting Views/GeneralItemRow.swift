//
// GeneralItemRow.swift
// Proton Pass - Created on 06/03/2023.
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct GeneralItemRow<ThumbnailView: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    let thumbnailView: ThumbnailView
    let title: String
    let titleLineLimit: Int
    let secondaryTitle: String?
    let secondaryTitleColor: UIColor?
    let description: String?
    let descriptionLineLimit: Int
    let hasTotp: Bool
    let isShared: Bool
    let showTitleDiscovery: Bool

    init(@ViewBuilder thumbnailView: () -> ThumbnailView,
         title: String,
         titleLineLimit: Int = 1,
         description: String?,
         descriptionLineLimit: Int = 1,
         secondaryTitle: String? = nil,
         secondaryTitleColor: UIColor? = nil,
         hasTotp: Bool = false,
         isShared: Bool = false,
         showTitleDiscovery: Bool = false) {
        self.thumbnailView = thumbnailView()
        self.title = title
        self.titleLineLimit = titleLineLimit
        self.description = description
        self.descriptionLineLimit = descriptionLineLimit
        self.secondaryTitle = secondaryTitle
        self.secondaryTitleColor = secondaryTitleColor
        self.hasTotp = hasTotp
        self.isShared = isShared
        self.showTitleDiscovery = showTitleDiscovery
    }

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack {
                Spacer()
                thumbnailView
                    .frame(width: 40)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(titleTexts)
                        .lineLimit(titleLineLimit)
                        .multilineTextAlignment(.leading)
                        .truncationMode(secondaryTitle == nil ? .tail : .middle)
                        .frame(alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if hasTotp {
                        Image(uiImage: PassIcon.shieldLock)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(PassColor.loginInteractionNormMajor1.toColor)
                    }

                    if isShared {
                        Image(uiImage: IconProvider.usersFilled)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(PassColor.textNorm.toColor)
                    }
                }
                .if(showTitleDiscovery) { view in
                    view.featureDiscovery(mode: .trailing(.init(alignment: .leading,
                                                                badgeMode: .newLabel)))
                }

                if let description, !description.isEmpty {
                    Text(description)
                        .font(.callout)
                        .lineLimit(descriptionLineLimit)
                        .minimumScaleFactor(descriptionLineLimit > 1 ? 0.75 : 1.0)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
    }

    var titleTexts: [Text] {
        var result = [Text]()
        let titleText = Text(title)
            .adaptiveForegroundStyle((isEnabled ? PassColor.textNorm : PassColor.textWeak).toColor)
        result.append(titleText)
        if let secondaryTitle {
            result.append(Text(verbatim: " "))
            let secondaryText = Text(secondaryTitle)
                .adaptiveForegroundStyle((isEnabled ?
                        (secondaryTitleColor ?? PassColor.textNorm) : PassColor.textWeak).toColor)
            result.append(secondaryText)
        }
        return result
    }
}
