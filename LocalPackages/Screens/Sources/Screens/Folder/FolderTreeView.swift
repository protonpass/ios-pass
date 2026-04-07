//
// FolderTreeView.swift
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
import ProtonCoreUIFoundations
import SwiftUI

public struct FolderTreeView<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let content: ShareContent
    let folders: [FolderUiModel]
    let shouldDismissOnSelection: Bool
    private var trailingView: (FolderUiModel, ShareContent) -> Content
    @Binding var expandedContainerIds: Set<String>
    @Binding var selectedContainer: ShareSelectionPayload?

    public init(content: ShareContent,
                folders: [FolderUiModel],
                shouldDismissOnSelection: Bool,
                expandedContainerIds: Binding<Set<String>>,
                selectedContainer: Binding<ShareSelectionPayload?>,
                @ViewBuilder trailingView: @escaping (FolderUiModel, ShareContent) -> Content) {
        self.content = content
        self.folders = folders
        self.shouldDismissOnSelection = shouldDismissOnSelection
        self.trailingView = trailingView
        _expandedContainerIds = expandedContainerIds
        _selectedContainer = selectedContainer
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(folders) { folder in
                row(for: folder)
                    .padding(.vertical, 12)

                if expandedContainerIds.contains(folder.id),
                   let subFolders = content.folders(in: folder.folderId) {
                    FolderTreeView(content: content,
                                   folders: subFolders,
                                   shouldDismissOnSelection: shouldDismissOnSelection,
                                   expandedContainerIds: $expandedContainerIds,
                                   selectedContainer: $selectedContainer,
                                   trailingView: trailingView)
                        .padding(.leading, 16)
                }
            }
        }
    }

    private func toggleDisplayContainerContent(containerId: String) {
        if expandedContainerIds.remove(containerId) == nil {
            expandedContainerIds.insert(containerId)
        }
    }
}

private extension FolderTreeView {
    func row(for folder: FolderUiModel) -> some View {
        HStack(spacing: 16) {
            disclosureButton(for: folder)
            folderButton(for: folder)
        }
    }

    func disclosureButton(for folder: FolderUiModel) -> some View {
        let hasSubfolders = content.containsSubfolders(containerId: folder.folderId)
        return Button {
            toggleDisplayContainerContent(containerId: folder.id)
        } label: {
            ExpandRowButtonDisplay(expanded: expandedContainerIds.contains(folder.id))
        }
        .buttonStyle(.plain)
        .opacityReduced(!hasSubfolders, reducedOpacity: 0)
    }

    func folderButton(for folder: FolderUiModel) -> some View {
        HStack {
            Button {
                if shouldDismissOnSelection {
                    dismiss()
                }
                selectedContainer = ShareSelectionPayload(share: content.share, folder: folder)
            } label: {
                HStack {
                    ZStack(alignment: .bottomTrailing) {
                        IconProvider.foldersFilled
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(PassColor.folderIcon)

                        if selectedContainer?.folder == folder {
                            IconProvider.checkmark
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(PassColor.textInvert)
                                .padding(1)
                                .background(colorScheme == .dark ?
                                    PassColor.interactionNormMajor2 : PassColor.interactionNorm)
                                .frame(height: 15)
                                .clipShape(.circle)
                                .offset(x: 5, y: 5)
                        }
                    }

                    Text(folder.content.name)
                        .lineLimit(1)
                        .foregroundStyle(PassColor.textNorm)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            trailingView(folder, content)
        }
    }
}

public extension FolderTreeView where Content == EmptyView {
    init(content: ShareContent,
         folders: [FolderUiModel],
         shouldDismissOnSelection: Bool,
         expandedContainerIds: Binding<Set<String>>,
         selectedContainer: Binding<ShareSelectionPayload?>) {
        self.init(content: content,
                  folders: folders,
                  shouldDismissOnSelection: shouldDismissOnSelection,
                  expandedContainerIds: expandedContainerIds,
                  selectedContainer: selectedContainer,
                  trailingView: { _, _ in EmptyView() })
    }
}
