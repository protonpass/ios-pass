//
// FolderMoveListViewModel.swift
// Proton Pass - Created on 04/02/2026.
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
import Entities
import FactoryKit
import Foundation

@MainActor
@Observable
final class FolderMoveListViewModel {
    @ObservationIgnored
    @LazyInjected(\SharedServiceContainer.appContentManager) private var appContentManager
    @ObservationIgnored
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @ObservationIgnored
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @ObservationIgnored
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus

    private(set) var loading: Bool = false
    var selectedContainer: ShareSelectionPayload = .default
    var containersExtended = Set<String>()
    var folderSupported: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passFolder)
    }

    func move(currentFolderId: String) {
        guard selectedContainer != .default, !loading else {
            return
        }
        Task {
            defer {
                loading = false
            }

            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.moveFolder(userId: userId,
                                                       shareId: selectedContainer.share.id,
                                                       folderId: currentFolderId,
                                                       newParentFolderId: selectedContainer.folder?.id)
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func load(folderInfos: FolderToMove) {
        selectedContainer = .init(share: folderInfos.shareContent.share, folder: folderInfos.folder)
        containersExtended.insert(folderInfos.shareContent.share.id)
        for folder in folderInfos.shareContent.allFolders {
            containersExtended.insert(folder.id)
        }
    }

    func toggleDisplayContainerContent(containerId: String) {
        if containersExtended.contains(containerId) {
            containersExtended.remove(containerId)
        } else {
            containersExtended.insert(containerId)
        }
    }
}
