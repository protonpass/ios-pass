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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let uiModel = viewModel.uiModel
        VStack(spacing: DesignConstant.sectionPadding) {
            HStack {
                GeneralItemRow(thumbnailView: {
                                   ItemSquircleThumbnail(data: uiModel.itemContent.thumbnailData())
                               },
                               title: uiModel.itemContent.title,
                               description: uiModel.itemContent.loginItem?.authIdentifier ?? "")
                if viewModel.uiModel.mode == .edit {
                    CircleButton(icon: IconProvider.chevronRight,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "View details",
                                 action: { viewModel.viewItemDetail() })
                }
            }
            .frame(height: 70)
            .padding(.top, 45)

            HStack {
                infoCell(title: #localized("Expires in:"),
                         description: uiModel.relativeTimeRemaining ?? "",
                         icon: IconProvider.clock)

                infoCell(title: uiModel.readTitle,
                         description: uiModel.readDescription,
                         icon: IconProvider.eye)
            }
            .frame(height: 80)
            .padding(.bottom, 10)

            Text(verbatim: uiModel.url)
                .foregroundStyle(PassColor.textNorm)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .contentShape(.rect)
                .onTapGesture { viewModel.copyLink() }
                .background(PassColor.interactionNormMinor1)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            CapsuleTextButton(title: #localized("Copy link"),
                              titleColor: PassColor.interactionNormMinor1,
                              backgroundColor: PassColor.interactionNormMajor2,
                              height: 48,
                              action: { viewModel.copyLink() })

            ShareLink(item: uiModel.url) {
                CapsuleTextButton(title: #localized("Share link"),
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: PassColor.interactionNormMinor1,
                                  height: 48)
            }

            Button {
                if uiModel.mode == .create {
                    dismiss()
                    viewModel.showSecureLinkList()
                } else {
                    viewModel.deleteLink(link: uiModel)
                }
            } label: {
                Text(uiModel.linkActionTitle)
                    .foregroundStyle(uiModel.mode == .create ? PassColor.interactionNormMajor2 : PassColor
                        .passwordInteractionNormMajor2)
            }.frame(height: 48)
            Spacer()
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .showSpinner(viewModel.loading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassColor.backgroundNorm)
        .onChange(of: viewModel.finishedDeleting) { _ in
            dismiss()
        }
    }
}

private extension SecureLinkDetailView {
    func infoCell(title: String, description: String, icon: Image) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack {
                Spacer()
                icon
                    .scaledToFit()
                    .frame(width: 14)
                    .foregroundStyle(PassColor.interactionNormMajor2)
                Spacer()
            }
            VStack(alignment: .leading) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak)
                Text(description)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(PassColor.interactionNormMinor1)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
