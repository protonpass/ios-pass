//
// ContainerDestinationSelectionView.swift
// Proton Pass - Created on 27/07/2026.
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

import Client
import DesignSystem
import DIComposition
import Entities
import FactoryKit
import Stores
import SwiftUI

public struct ContainerDestinationSelectionView: View {
    @Binding private var selectedContainer: ShareSelectionPayload
    private let isFreeUser: Bool
    private let onUpgrade: () -> Void

    @State private var expandedContainerIds = Set<String>()
    @State private var shares: [ShareContent] = []

    private let appContentManager = dependency(\ServiceContainer.appContentManager)
    private let getFeatureFlagStatus = dependency(\UseCasesContainer.getFeatureFlagStatus)

    public init(selectedContainer: Binding<ShareSelectionPayload>,
                isFreeUser: Bool,
                onUpgrade: @escaping () -> Void) {
        _selectedContainer = selectedContainer
        self.isFreeUser = isFreeUser
        self.onUpgrade = onUpgrade
    }

    public var body: some View {
        NavigationStack {
            VStack {
                if isFreeUser {
                    LimitedVaultOperationsBanner(onUpgrade: onUpgrade)
                        .padding([.horizontal, .top])
                }

                ContainerList(shares: shares,
                              folderSupported: getFeatureFlagStatus(for: FeatureFlagType.passFolder),
                              expandedContainerIds: $expandedContainerIds,
                              selectedContainer: $selectedContainer)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(PassColor.backgroundWeak)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select a destination", bundle: .module)
                        .navigationTitleText()
                }
            }
        }
        .task(id: selectedContainer.id) {
            load()
        }
        .onReceive(appContentManager.$state) { _ in
            shares = appContentManager.getAllEditableVaultContents().sortedByHidden()
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

private struct ContainerList: View {
    let shares: [ShareContent]
    let folderSupported: Bool
    @Binding var expandedContainerIds: Set<String>
    @Binding var selectedContainer: ShareSelectionPayload

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(shares) { shareContent in
                    ContainerRow(content: shareContent,
                                 folderSupported: folderSupported,
                                 expandedContainerIds: $expandedContainerIds,
                                 selectedContainer: $selectedContainer)
                        .equatable()
                        .padding(.horizontal)
                    if shareContent.id != shares.last?.id {
                        PassDivider()
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

private struct ContainerRow: View {
    private let content: ShareContent
    @Binding private var expandedContainerIds: Set<String>
    @Binding private var selectedContainer: ShareSelectionPayload
    private let folders: [FolderUiModel]?

    init(content: ShareContent,
         folderSupported: Bool,
         expandedContainerIds: Binding<Set<String>>,
         selectedContainer: Binding<ShareSelectionPayload>) {
        self.content = content
        folders = if folderSupported {
            content.folders(in: content.id)?.nilIfEmpty
        } else {
            nil
        }
        _expandedContainerIds = expandedContainerIds
        _selectedContainer = selectedContainer
    }

    var body: some View {
        if let vaultContent = content.share.vaultContent {
            HStack(spacing: 16) {
                if folders != nil {
                    Button {
                        withAnimation {
                            if expandedContainerIds.remove(content.id) == nil {
                                expandedContainerIds.insert(content.id)
                            }
                        }
                    } label: {
                        ExpandRowButtonDisplay(expanded: expandedContainerIds.contains(content.id))
                    }
                    .buttonStyle(.plain)
                }

                VaultSelectionRow(content: content,
                                  vaultContent: vaultContent,
                                  selectedContainer: $selectedContainer)
            }

            if let folders, expandedContainerIds.contains(content.id) {
                FolderTreeView(content: content,
                               folders: folders,
                               shouldDismissOnSelection: true,
                               expandedContainerIds: $expandedContainerIds,
                               selectedContainer: $selectedContainer.asOptional())
                    .padding(.leading, 30)
            }
        }
    }
}

// swiftformat:disable redundantEquatable
extension ContainerRow: Equatable {
    static func == (lhs: ContainerRow, rhs: ContainerRow) -> Bool {
        lhs.content == rhs.content &&
            lhs.folders == rhs.folders &&
            lhs.expandedContainerIds == rhs.expandedContainerIds &&
            lhs.selectedContainer == rhs.selectedContainer
    }
}

// swiftformat:enable redundantEquatable

private struct VaultSelectionRow: View {
    @Environment(\.dismiss) private var dismiss
    let content: ShareContent
    let vaultContent: VaultContent
    @Binding var selectedContainer: ShareSelectionPayload

    var body: some View {
        Button(action: {
            selectedContainer = ShareSelectionPayload(share: content.share, folder: nil)
            dismiss()
        }, label: {
            VaultRow(thumbnail: { VaultThumbnail(vaultContent: vaultContent) },
                     title: vaultContent.name,
                     itemCount: content.itemCount,
                     mode: .view(isSelected: selectedContainer.share == content.share &&
                         selectedContainer.isFolderSelected == false,
                         isHidden: content.share.hidden,
                         action: nil),
                     height: 74)
        })
        .buttonStyle(.plain)
    }
}
