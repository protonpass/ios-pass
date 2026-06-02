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
import Macro

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
    @LazyInjected(\SharedToolingContainer.logger) private var logger

    private(set) var loading = false
    private(set) var moveCompleted = false
    @ObservationIgnored private var moveTask: Task<Void, Never>?
    @ObservationIgnored private var folderToMove: FolderToMove?
    var expandedContainerIds = Set<String>()

    // swiftlint:disable:next todo
    // TODO: fetch from BE
    private var folderLimits = FolderLimits.default

    deinit {
        moveTask?.cancel()
    }

    init() {}

    func move(selectedContainer: ShareSelectionPayload, currentFolderId: String) {
        guard !loading else { return }

        if let folderToMove {
            do {
                try folderToMove.shareContent.validateMove(folderId: currentFolderId,
                                                           to: selectedContainer.folder?.folderId,
                                                           limits: folderLimits)
            } catch let PassError.folder(reason) {
                router.display(element: .errorMessage(reason.userFacingMessage))
                return
            } catch {
                router.display(element: .displayErrorBanner(error))
                return
            }
        }

        moveTask?.cancel()
        moveTask = Task {
            defer { loading = false }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.moveFolder(userId: userId,
                                                       shareId: selectedContainer.share.id,
                                                       folderId: currentFolderId,
                                                       newParentFolderId: selectedContainer.folder?.folderId)
                moveCompleted = true
            } catch {
                logger.error(message: "Failed to move folder", error: error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func load(folderInfos: FolderToMove) {
        folderToMove = folderInfos
        expandedContainerIds.insert(folderInfos.shareContent.share.id)
        for folder in folderInfos.shareContent.allFolders {
            expandedContainerIds.insert(folder.id)
        }
    }

    func toggleDisplayContainerContent(containerId: String) {
        if expandedContainerIds.remove(containerId) == nil {
            expandedContainerIds.insert(containerId)
        }
    }
}

private extension PassError.FolderFailureReason {
    var userFacingMessage: String {
        switch self {
        case let .layerFull(containerName, limit):
            #localized("%@ has reached the limit of %lld sub-folders", containerName,
                       limit)

        case let .depthExceeded(containerName, limit):
            #localized("%@ cannot be nest more than %lld levels deep", containerName,
                       limit)

        case let .vaultFull(containerName, limit):
            #localized("%@ has reached the limit of %lld folders", containerName,
                       limit)
        }
    }
}
