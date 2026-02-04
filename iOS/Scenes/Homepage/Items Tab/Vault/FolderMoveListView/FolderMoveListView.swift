//
// FolderMoveListView.swift
// Proton Pass - Created on 03/02/2026.
// Copyright (c) 2026 Proton Technologies AG
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

struct FolderMoveListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FolderMoveListViewModel()

    let folderToMove: FolderToMove
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .center) {
                Text("Select a destination")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm)
                Label("You cannot move a folder to on of his child folders", systemImage: "info.circle.fill")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(PassColor.backgroundNorm)
                    .cornerRadius(12)
                Divider()
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.top, 30)

            ScrollView {
                VStack(spacing: 0) {
                    fullRow(content: folderToMove.shareContent)
                }
                .padding(.horizontal)
            }

            HStack(spacing: 16) {
                CapsuleTextButton(title: #localized("Cancel"),
                                  titleColor: PassColor.textWeak,
                                  backgroundColor: PassColor.textDisabled,
                                  height: 44,
                                  action: {
                                      onDismiss()
                                      dismiss()
                                  })

                DisablableCapsuleTextButton(title: #localized("Confirm"),
                                            titleColor: PassColor.textInvert,
                                            disableTitleColor: PassColor.textHint,
                                            backgroundColor: PassColor.interactionNormMajor1,
                                            disableBackgroundColor: PassColor.interactionNormMinor1,
                                            disabled: viewModel.selectedContainer == .default,
                                            height: 44,
                                            action: {
                                                viewModel.move(currentFolderId: folderToMove.folder.id)
                                                onDismiss()
                                                dismiss()
                                            })
            }
            .padding([.bottom, .horizontal])
        }
        .background(PassColor.backgroundWeak)
        .frame(maxWidth: .infinity, alignment: .leading)
        .showSpinner(viewModel.loading)
        .task(id: folderToMove.id) {
            viewModel.load(folderInfos: folderToMove)
        }
    }

    @ViewBuilder
    private func fullRow(content: ShareContent) -> some View {
        if let vaultContent = content.share.vaultContent {
            HStack {
                if let folders = content.folders(in: content.id), !folders.isEmpty {
                    Button { viewModel.toggleDisplayContainerContent(containerId: content.id) } label: {
                        (viewModel.containersExtended.contains(content.id) ?
                            IconProvider.chevronDownFilled : IconProvider.chevronRightFilled)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(PassColor.textWeak)
                    }
                    .buttonStyle(.plain)
                }
                view(for: content, vaultContent: vaultContent)
            }

            if let folders = content.folders(in: content.id),
               !folders.isEmpty, viewModel.containersExtended.contains(content.id) {
                FolderTreeView(content: content,
                               share: content.share,
                               folders: folders,
                               shouldDismissOnSelection: false,
                               containersExtended: $viewModel.containersExtended,
                               selectedContainer: $viewModel.selectedContainer)
            }
        }
    }

    private func view(for vaultInfos: ShareContent, vaultContent: VaultContent) -> some View {
        Button(action: {
            viewModel
                .selectedContainer = ShareSelectionPayload(share: vaultInfos.share,
                                                           folder: nil)
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vaultInfos.itemCount,
                     mode: .view(isSelected: viewModel.selectedContainer.share == vaultInfos.share && viewModel
                         .selectedContainer.folder == nil,
                         isHidden: vaultInfos.share.hidden,
                         action: nil),
                     height: 74)
        })
        .buttonStyle(.plain)
    }
}
