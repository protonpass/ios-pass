//
// AppContentManager.swift
// Proton Pass - Created on 22/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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

// import Core
// import Entities
//
// public protocol AppContentManagerServicing: Actor {
//    func shareItemItems() async throws -> [ItemUiModel]
// }
//
///// This manager contains all the logic to handle and display app content shares/items/vaults
// public actor AppContentManager: AppContentManagerServicing {
//    private let userManager: any UserManagerProtocol
//    private let itemRepository: any ItemRepositoryProtocol
//    private let shareRepository: any ShareRepositoryProtocol
//    private let logger: Logger
//
//    public init(userManager: any UserManagerProtocol,
//                itemRepository: any ItemRepositoryProtocol,
//                shareRepository: any ShareRepositoryProtocol,
//                logManager: any LogManagerProtocol) {
//        self.userManager = userManager
//        self.itemRepository = itemRepository
//        self.shareRepository = shareRepository
//        logger = .init(manager: logManager)
//    }
// }
//
//// MARK: - Item share
//
// public extension AppContentManager {
//    func shareItemItems() async throws -> [ItemUiModel] {
//        let userId = try await userManager.getActiveUserId()
//        let shares = try await shareRepository.getShares(userId: userId).filter { $0.share.shareType == .item }
//        var items: [ItemUiModel] = []
//        for encryptedShare in shares {
//            let newItems = try await itemRepository.fetchAndRefreshItems(userId: userId,
//                                                                         shareId: encryptedShare.share.shareID)
//            items.append(contentsOf: newItems.map(\.toItemUiModel))
//        }
//        return items
//    }
// }
