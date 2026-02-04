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
import Entities
import FactoryKit
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct VaultSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedContainer: ShareSelectionPayload
    let isFreeUser: Bool
    let onUpgrade: () -> Void

    @State private var containersExtended = Set<String>()

    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    private let getFeatureFlagStatus = resolve(\SharedUseCasesContainer.getFeatureFlagStatus)

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
        }
    }

    private func toggleDisplayContainerContent(containerId: String) {
        if containersExtended.contains(containerId) {
            containersExtended.remove(containerId)
        } else {
            containersExtended.insert(containerId)
        }
    }
}

// MARK: - Views

private extension VaultSelectorView {
    var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 0) {
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
    }

    @ViewBuilder
    private func fullRow(content: ShareContent) -> some View {
        if let vaultContent = content.share.vaultContent {
            HStack {
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
                (containersExtended.contains(content.id) ?
                    IconProvider.chevronDownFilled : IconProvider.chevronRightFilled)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(PassColor.textWeak)
            }
            .buttonStyle(.plain)
        }
    }

    func vaultRow(for vaultInfos: ShareContent, vaultContent: VaultContent) -> some View {
        Button(action: {
            selectedContainer = ShareSelectionPayload(share: vaultInfos.share, folder: nil)
            dismiss()
        }, label: {
            // TODO: update view to take into account folder
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: vaultInfos.itemCount,
                     mode: .view(isSelected: selectedContainer.share == vaultInfos.share,
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
           !folders.isEmpty, containersExtended.contains(content.id) {
            FolderTreeView(content: content,
                           share: content.share,
                           folders: folders,
                           shouldDismissOnSelection: true,
                           containersExtended: $containersExtended,
                           selectedContainer: $selectedContainer)
        }
    }
}
