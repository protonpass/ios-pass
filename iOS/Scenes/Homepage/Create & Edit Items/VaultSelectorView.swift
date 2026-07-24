//
// VaultSelectorView.swift
// Proton Pass - Created on 12/04/2023.
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
import DIComposition
import Entities
import FactoryKit
import ProtonCoreUIFoundations
import Screens
import Stores
import SwiftUI

struct VaultSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedContainer: ShareSelectionPayload
    let isFreeUser: Bool
    let onUpgrade: () -> Void

    @State private var expandedContainerIds = Set<String>()

    private let appContentManager = dependency(\ServiceContainer.appContentManager)
    private let getFeatureFlagStatus = dependency(\UseCasesContainer.getFeatureFlagStatus)

    private var shares: [ShareContent] {
        appContentManager
            .getAllEditableVaultContents()
            .sortedByHidden()
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isFreeUser {
                    LimitedVaultOperationsBanner(onUpgrade: onUpgrade)
                        .padding([.horizontal, .top])
                }

                mainScrollView
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(PassColor.backgroundWeak)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select a vault")
                        .navigationTitleText()
                }
            }
        }.task(id: selectedContainer.id) {
            load()
        }
    }

    private func toggleDisplayContainerContent(containerId: String) {
        if expandedContainerIds.remove(containerId) == nil {
            expandedContainerIds.insert(containerId)
        }
    }

    func load() {
        if selectedContainer.isFolderSelected {
            expandedContainerIds.insert(selectedContainer.share.id)
            if let shareContent = appContentManager.getShareContent(for: selectedContainer.share.id) {
                for folder in shareContent.flattenedFolders(from: selectedContainer.share.id) {
                    expandedContainerIds.insert(folder.id)
                }
            }
        }
    }
}

// MARK: - Views

private extension VaultSelectorView {
    var mainScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(shares) { shareContent in
                    fullRow(content: shareContent)
                        .padding(.horizontal)
                    if shareContent != shares.last {
                        PassDivider()
                            .padding(.horizontal)
                    }
                }
            }
        }
        .animation(.default, value: expandedContainerIds)
    }

    @ViewBuilder
    private func fullRow(content: ShareContent) -> some View {
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
        if getFeatureFlagStatus(for: FeatureFlagType.passFolder), let folders = content.folders(in: content.id),
           !folders.isEmpty {
            Button { toggleDisplayContainerContent(containerId: content.id) } label: {
                ExpandRowButtonDisplay(expanded: expandedContainerIds.contains(content.id))
            }
            .buttonStyle(.plain)
        }
    }

    func vaultRow(for vaultInfos: ShareContent, vaultContent: VaultContent) -> some View {
        Button(action: {
            selectedContainer = ShareSelectionPayload(share: vaultInfos.share, folder: nil)
            dismiss()
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vaultInfos.itemCount,
                     mode: .view(isSelected: selectedContainer.share == vaultInfos.share &&
                         selectedContainer.isFolderSelected == false,
                         isHidden: vaultInfos.share.hidden,
                         action: nil),
                     height: 74)
        })
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func folderRow(content: ShareContent) -> some View {
        if getFeatureFlagStatus(for: FeatureFlagType.passFolder),
           let folders = content.folders(in: content.id),
           !folders.isEmpty, expandedContainerIds.contains(content.id) {
            FolderTreeView(content: content,
                           folders: folders,
                           shouldDismissOnSelection: true,
                           expandedContainerIds: $expandedContainerIds,
                           selectedContainer: $selectedContainer.asOptional())
                .padding(.leading, 30)
        }
    }
}
