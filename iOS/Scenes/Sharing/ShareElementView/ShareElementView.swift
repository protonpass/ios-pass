//
// ShareOrCreateNewVaultView.swift
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

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Share")
                .font(.body.bold())
                .foregroundStyle(PassColor.textNorm.toColor)

            Spacer()

            if viewModel.itemSharingEnabled, viewModel.share.canShareWithMorePeople {
                itemSharing
                    .padding(.vertical)
            }

            if !viewModel.itemContent.isAlias {
                secureLink
            }

            if viewModel.share.shared {
                manageAccessButton
                    .padding(.vertical)
            } else if viewModel.share.isVaultRepresentation,
                      let vaultContent = viewModel.share.vaultContent {
                currentVault(vaultContent: vaultContent)
                    .padding(.top, 22)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 44)
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
        .background(PassColor.backgroundNorm.toColor)
    }
}

private extension ShareElementView {
    var itemSharing: some View {
        HStack {
            SquircleThumbnail(data: .icon(IconProvider.userPlus),
                              tintColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1)
            VStack(alignment: .leading) {
                Text("Share with")
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Share this item with other Proton users.")
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

                Text("Generate a secure link to this item")
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

                Text("The item's vault is currently shared with \(viewModel.share.members) users")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
    func currentVault(vaultContent: VaultContent) -> some View {
        Button { viewModel.shareVault() } label: {
            Text("Share entire vault instead?")
                .foregroundStyle(PassColor.interactionNorm.toColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
