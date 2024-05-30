//
// SecureLinkDetailView.swift
// Proton Pass - Created on 29/05/2024.
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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct SecureLinkDetailView: View {
    @StateObject var viewModel: SecureLinkDetailViewModel

    var body: some View {
        let uiModel = viewModel.uiModel
        VStack(spacing: DesignConstant.sectionPadding) {
            HStack(spacing: DesignConstant.sectionPadding) {
                GeneralItemRow(thumbnailView: {
                                   ItemSquircleThumbnail(data: uiModel.itemContent.thumbnailData())
                               },
                               title: uiModel.itemContent.title,
                               description: uiModel.itemContent.loginItem?.authIdentifier ?? "")
                Spacer()
                CircleButton(icon: IconProvider.squares,
                             iconColor: PassColor.interactionNormMajor1,
                             backgroundColor: PassColor.interactionNormMinor2,
                             action: { viewModel.copyLink() })

                ShareLink(item: uiModel.url) {
                    CircleButton(icon: IconProvider.arrowUpFromSquare,
                                 iconColor: PassColor.interactionNormMajor1,
                                 backgroundColor: PassColor.interactionNormMinor2)
                }
            }

            HStack {
                infoCell(title: #localized("Expires in:"),
                         description: uiModel.relativeTimeRemaining ?? "",
                         icon: IconProvider.clock)

                infoCell(title: uiModel.readTitle,
                         description: uiModel.readDescription,
                         icon: IconProvider.eye)
            }

            Text(verbatim: uiModel.url)
                .foregroundStyle(PassColor.textNorm.toColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .contentShape(.rect)
                .onTapGesture { viewModel.copyLink() }
                .background(PassColor.interactionNormMinor1.toColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
    }
}

private extension SecureLinkDetailView {
    func infoCell(title: String, description: String, icon: UIImage) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack {
                Spacer()
                Image(uiImage: icon)
                    .scaledToFit()
                    .frame(width: 14)
                    .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                Spacer()
            }
            VStack(alignment: .leading) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                Text(description)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(PassColor.interactionNormMinor1.toColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
