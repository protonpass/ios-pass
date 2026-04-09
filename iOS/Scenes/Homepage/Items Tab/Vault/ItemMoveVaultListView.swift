//
// ItemMoveVaultListView.swift
// Proton Pass - Created on 29/03/2023.
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
import Screens
import SwiftUI

struct ItemMoveVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ItemMoveVaultListViewModel

    var body: some View {
        VStack(alignment: .leading) {
            header
            freeBanner
            mainScrollView
            bottomActionsBar
        }
        .background(PassColor.backgroundWeak)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.default, value: viewModel.isFreeUser)
    }
}

private extension ItemMoveVaultListView {
    var header: some View {
        VStack(alignment: .center) {
            Text("Select a container")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm)

            if viewModel.showWarning {
                // swiftlint:disable:next line_length
                Label("When moving items between containers we will preserve up to the last 50 modifications performed to each item",
                      systemImage: "info.circle.fill")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(PassColor.backgroundNorm)
                    .cornerRadius(12)

                Divider()
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, 30)
    }

    @ViewBuilder
    var freeBanner: some View {
        if viewModel.isFreeUser {
            LimitedVaultOperationsBanner(onUpgrade: { viewModel.upgrade() })
                .padding([.horizontal, .top])
        }
    }

    var mainScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.allSharesContent) { shareContent in
                    fullRow(content: shareContent)
                    if shareContent != viewModel.allSharesContent.last {
                        PassDivider()
                    }
                }
            }
            .padding(.horizontal)
        }
        .animation(.default, value: viewModel.expandedContainerIds)
    }

    var bottomActionsBar: some View {
        HStack(spacing: 16) {
            CapsuleTextButton(title: #localized("Cancel"),
                              titleColor: PassColor.textWeak,
                              backgroundColor: PassColor.textDisabled,
                              height: 44,
                              action: dismiss.callAsFunction)

            DisablableCapsuleTextButton(title: #localized("Confirm"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: viewModel.selectedContainer == nil,
                                        height: 44,
                                        action: { dismiss(); viewModel.doMove() })
        }
        .padding([.bottom, .horizontal])
    }

    @ViewBuilder
    func fullRow(content: ShareContent) -> some View {
        if let vaultContent = content.share.vaultContent {
            HStack(spacing: 16) {
                expandVaultRow(content: content)
                vaultRow(for: content, vaultContent: vaultContent)
            }
            folderRow(content: content)
        }
    }

    @ViewBuilder
    func expandVaultRow(content: ShareContent) -> some View {
        if viewModel.folderSupported,
           let folders = content.folders(in: content.id), !folders.isEmpty {
            Button { viewModel.toggleDisplayContainerContent(containerId: content.id) } label: {
                ExpandRowButtonDisplay(expanded: viewModel.expandedContainerIds.contains(content.id))
            }
            .buttonStyle(.plain)
        }
    }

    func vaultRow(for vaultInfos: ShareContent, vaultContent: VaultContent) -> some View {
        Button(action: {
            viewModel.selectedContainer = ShareSelectionPayload(share: vaultInfos.share,
                                                                folder: nil)
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vaultInfos.itemCount,
                     mode: .view(isSelected: viewModel.selectedContainer?.share == vaultInfos.share && viewModel
                         .selectedContainer?.folder == nil,
                         isHidden: vaultInfos.share.hidden,
                         action: nil),
                     height: 74)
        })
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func folderRow(content: ShareContent) -> some View {
        if viewModel.folderSupported, viewModel.expandedContainerIds.contains(content.id),
           let folders = content.folders(in: content.id), !folders.isEmpty {
            FolderTreeView(content: content,
                           folders: folders,
                           shouldDismissOnSelection: false,
                           expandedContainerIds: $viewModel.expandedContainerIds,
                           selectedContainer: $viewModel.selectedContainer)
                .padding(.leading, 30)
        }
    }
}
