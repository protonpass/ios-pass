//
// BaseCreateEditItemViewModel.swift
// Proton Pass - Created on 19/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Core
import ProtonCore_Login

enum ItemMode {
    case create(shareId: String)
    case edit(ItemContent)
}

class BaseCreateEditItemViewModel: BaseViewModel {
    let mode: ItemMode
    let userData: UserData
    let shareRepository: ShareRepositoryProtocol
    let shareKeysRepository: ShareKeysRepositoryProtocol
    let itemRevisionRepository: ItemRevisionRepositoryProtocol

    var onCreatedItem: ((ItemContentType) -> Void)?
    var onUpdatedItem: ((ItemContentType) -> Void)?

    init(mode: ItemMode,
         userData: UserData,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        self.mode = mode
        self.userData = userData
        self.shareRepository = shareRepository
        self.shareKeysRepository = shareKeysRepository
        self.itemRevisionRepository = itemRevisionRepository
        super.init()
        bindValues()
    }

    /// To be overridden by subclasses
    func bindValues() {}

    // swiftlint:disable:next unavailable_function
    func navigationBarTitle() -> String {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:disable:next unavailable_function
    func itemContentType() -> ItemContentType {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:disable:next unavailable_function
    func generateItemContent() -> ItemContentProtobuf {
        fatalError("Must be overridden by subclasses")
    }

    func save() {
        switch mode {
        case .create(let shareId):
            createItem(shareId: shareId)
        case .edit(let oldItemContent):
            editItem(oldItemContent: oldItemContent)
        }
    }

    private func createItem(shareId: String) {
        Task { @MainActor in
            do {
                isLoading = true
                let itemContent = generateItemContent()

                let (latestVaultKey, latestItemKey) =
                try await shareKeysRepository.getLatestVaultItemKey(shareId: shareId, forceRefresh: false)
                let share = try await shareRepository.getShare(shareId: shareId)
                let vaultKeyPassphrase = try PassKeyUtils.getVaultKeyPassphrase(userData: userData,
                                                                                share: share,
                                                                                vaultKey: latestVaultKey)
                guard let itemKeyPassphrase =
                        try PassKeyUtils.getItemKeyPassphrase(vaultKey: latestVaultKey,
                                                              vaultKeyPassphrase: vaultKeyPassphrase,
                                                              itemKey: latestItemKey) else {
                    fatalError("Post MVP")
                }
                let request = try CreateItemRequest(vaultKey: latestVaultKey,
                                                    vaultKeyPassphrase: vaultKeyPassphrase,
                                                    itemKey: latestItemKey,
                                                    itemKeyPassphrase: itemKeyPassphrase,
                                                    addressKey: userData.getAddressKey(),
                                                    itemContent: itemContent)
                try await itemRevisionRepository.createItem(request: request, shareId: shareId)
                onCreatedItem?(itemContentType())
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }

    private func editItem(oldItemContent: ItemContent) {
        Task { @MainActor in
            do {
                let shareId = oldItemContent.shareId
                let itemId = oldItemContent.itemId
                isLoading = true
                guard let oldItemRevision =
                        try await itemRevisionRepository.getItemRevision(
                            shareId: oldItemContent.shareId,
                            itemId: oldItemContent.itemId) else {
                    isLoading = false
                    return
                }

                let (latestVaultKey, latestItemKey) =
                try await shareKeysRepository.getLatestVaultItemKey(shareId: shareId, forceRefresh: false)
                let share = try await shareRepository.getShare(shareId: shareId)
                let vaultKeyPassphrase = try PassKeyUtils.getVaultKeyPassphrase(userData: userData,
                                                                                share: share,
                                                                                vaultKey: latestVaultKey)
                guard let itemKeyPassphrase =
                        try PassKeyUtils.getItemKeyPassphrase(vaultKey: latestVaultKey,
                                                              vaultKeyPassphrase: vaultKeyPassphrase,
                                                              itemKey: latestItemKey) else {
                    fatalError("Post MVP")
                }

                let request = try UpdateItemRequest(oldRevision: oldItemRevision,
                                                    vaultKey: latestVaultKey,
                                                    vaultKeyPassphrase: vaultKeyPassphrase,
                                                    itemKey: latestItemKey,
                                                    itemKeyPassphrase: itemKeyPassphrase,
                                                    addressKey: userData.getAddressKey(),
                                                    itemContent: generateItemContent())
                try await itemRevisionRepository.updateItem(request: request,
                                                            shareId: shareId,
                                                            itemId: itemId)
                isLoading = false
                onUpdatedItem?(itemContentType())
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }
}
