//
//
// MoveItemsBetweenVaults.swift
// Proton Pass - Created on 13/09/2023.
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
//

import Client

// sourcery: AutoMockable
@MainActor
public protocol MoveItemsBetweenContainersUseCase: Sendable {
    func execute(context: MovingContext, to shareId: ShareID, destinationFolderId: String?) async throws
}

public extension MoveItemsBetweenContainersUseCase {
    func callAsFunction(context: MovingContext, to shareId: ShareID, destinationFolderId: String?) async throws {
        try await execute(context: context, to: shareId, destinationFolderId: destinationFolderId)
    }
}

@MainActor
public final class MoveItemsBetweenContainers: MoveItemsBetweenContainersUseCase {
    private let repository: any ItemRepositoryProtocol
    private let appContentManager: any AppContentManagerProtocol

    public init(repository: any ItemRepositoryProtocol,
                appContentManager: any AppContentManagerProtocol) {
        self.repository = repository
        self.appContentManager = appContentManager
    }

    public func execute(context: MovingContext, to shareId: ShareID, destinationFolderId: String?) async throws {
        switch context {
        case let .singleItem(item):
            try await repository.move(items: [item], toShareId: shareId, destinationFolderId: destinationFolderId)

        case let .allItems(fromVault):
            try await moveDirectItems(inShare: fromVault.shareId,
                                      container: fromVault.shareId,
                                      to: shareId,
                                      destinationFolderId: destinationFolderId)

        case let .allItemsInFolder(folder):
            try await moveDirectItems(inShare: folder.shareId,
                                      container: folder.folderId,
                                      to: shareId,
                                      destinationFolderId: destinationFolderId)

        case let .selectedItems(items):
            try await repository.move(items: items, toShareId: shareId, destinationFolderId: destinationFolderId)
        }
    }
}

private extension MoveItemsBetweenContainers {
    func moveDirectItems(inShare sourceShareId: String,
                         container containerId: String,
                         to shareId: ShareID,
                         destinationFolderId: String?) async throws {
        guard let shareContent = appContentManager.getShareContent(for: sourceShareId) else { return }
        let items = shareContent.items(in: containerId) ?? []
        guard !items.isEmpty else { return }
        try await repository.move(items: items,
                                  toShareId: shareId,
                                  destinationFolderId: destinationFolderId)
    }
}
