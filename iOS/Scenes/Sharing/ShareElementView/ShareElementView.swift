//
// ShareElementView.swift
// Proton Pass - Created on 03/10/2023.
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

@MainActor
struct ShareElementView: View {
    let viewModel: ShareElementViewModel
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Share")
                .font(.body.bold())
                .foregroundStyle(PassColor.textNorm.toColor)

            if !viewModel.isFreeUser, viewModel.itemSharingEnabled, viewModel.share.canShareWithMorePeople {
                itemSharing
            }

            if viewModel.isShared {
                manageAccessButton
                Divider()
            }

            if !viewModel.itemContent.isAlias {
                secureLink
            }

            if !viewModel.isShared, viewModel.share.isVaultRepresentation {
                currentVault
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 44)
        .background(GeometryReader { proxy in
            Color.clear
                .onAppear {
                    contentHeight += proxy.size.height
                }
        })
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
        .fullSheetBackground(PassColor.backgroundNorm.toColor)
        .onChange(of: contentHeight) { value in
            viewModel.updateSheetHeight(value)
        }
    }
}

private extension ShareElementView {
    var itemSharing: some View {
        // swiftlint:disable:next todo
        // TODO: add feature discovery
        HStack {
            SquircleThumbnail(data: .icon(IconProvider.userPlus),
                              tintColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1)
            VStack(alignment: .leading) {
                Text("With other Proton Pass users")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Useful for permanent sharing.")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.isFreeUser {
                Image(uiImage: PassIcon.passSubscriptionBadge)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            if viewModel.isFreeUser {
                viewModel.upsell(entryPoint: .secureLink)
            } else {
                viewModel.shareItem()
            }
        }
        .padding()
        .roundedEditableSection()
        .featureDiscoveryOverlay(feature: .itemSharing, config: .init(alignment: .topTrailing,
                                                                      offset: CGSize(width: -17, height: -12.5),
                                                                      shouldHideAfterAction: false)) {
            Text("NEW")
                .font(.caption)
                .foregroundStyle(PassColor.textInvert.toColor)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PassColor.signalInfo.toColor)
                .cornerRadius(6)
        }
    }
}

private extension ShareElementView {
    var secureLink: some View {
        HStack {
            SquircleThumbnail(data: .icon(IconProvider.link),
                              tintColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1)
            VStack(alignment: .leading) {
                Text("Via secure link")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("For one-off sharing.")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.isFreeUser {
                Image(uiImage: PassIcon.passSubscriptionBadge)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            if viewModel.isFreeUser {
                viewModel.upsell(entryPoint: .secureLink)
            } else {
                viewModel.secureLinkSharing()
            }
        }
        .padding()
        .roundedEditableSection()
    }
}

private extension ShareElementView {
    var manageAccessButton: some View {
        HStack {
            SquircleThumbnail(data: .icon(IconProvider.users),
                              tintColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1)
            VStack(alignment: .leading) {
                Text(viewModel.share.canEdit ? "Manage access" : "View members")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("See members and permission overview")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentShape(.rect)
        .padding()
        .roundedEditableSection()
        .onTapGesture { viewModel.manageAccess() }
    }
}

private extension ShareElementView {
    var currentVault: some View {
        Button { viewModel.shareVault() } label: {
            Text("Share entire vault instead?")
                .foregroundStyle(PassColor.interactionNorm.toColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
