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

protocol CreateEditItemViewModelDelegate: AnyObject {
    func createEditItemViewModelDidCreateItem(_ type: ItemContentType)
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType)
}

enum ItemMode {
    case create(shareId: String, alias: Bool)
    case edit(ItemContent)
}

class BaseCreateEditItemViewModel: BaseViewModel {
    let shareId: String
    let mode: ItemMode
    let userData: UserData
    let shareRepository: ShareRepositoryProtocol
    let shareKeysRepository: ShareKeysRepositoryProtocol
    let itemRevisionRepository: ItemRevisionRepositoryProtocol

    weak var createEditItemDelegate: CreateEditItemViewModelDelegate?

    init(mode: ItemMode,
         userData: UserData,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        switch mode {
        case .create(let shareId, _):
            self.shareId = shareId
        case .edit(let itemContent):
            self.shareId = itemContent.shareId
        }
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

    func generateAliasCreationInfo() -> AliasCreationInfo? { nil }

    func save() {
        switch mode {
        case let .create(shareId, alias):
            if alias {
                createAliasItem(shareId: shareId)
            } else {
                createItem(shareId: shareId)
            }

        case .edit(let oldItemContent):
            editItem(oldItemContent: oldItemContent)
        }
    }

    private func createItem(shareId: String) {
        Task { @MainActor in
            do {
                isLoading = true
                let request = try await createItemRequest(shareId: shareId)
                try await itemRevisionRepository.createItem(request: request, shareId: shareId)
                isLoading = false
                createEditItemDelegate?.createEditItemViewModelDidCreateItem(itemContentType())
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }

    private func createAliasItem(shareId: String) {
        guard let info = generateAliasCreationInfo() else { return }
        Task { @MainActor in
            do {
                isLoading = true
                let createItemRequest = try await createItemRequest(shareId: shareId)
                let request = CreateCustomAliasRequest(prefix: info.prefix,
                                                       signedSuffix: info.signedSuffix,
                                                       mailboxIDs: info.mailboxIds,
                                                       item: createItemRequest)
                try await itemRevisionRepository.createAlias(request: request, shareId: shareId)
                isLoading = false
                createEditItemDelegate?.createEditItemViewModelDidCreateItem(itemContentType())
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

                let keysAndPassphrases = try await getKeysAndPassphrases(shareId: shareId)

                let request = try UpdateItemRequest(oldRevision: oldItemRevision,
                                                    vaultKey: keysAndPassphrases.vaultKey,
                                                    vaultKeyPassphrase: keysAndPassphrases.vaultKeyPassphrase,
                                                    itemKey: keysAndPassphrases.itemKey,
                                                    itemKeyPassphrase: keysAndPassphrases.itemKeyPassphrase,
                                                    addressKey: keysAndPassphrases.addressKey,
                                                    itemContent: generateItemContent())
                try await itemRevisionRepository.updateItem(request: request,
                                                            shareId: shareId,
                                                            itemId: itemId)
                isLoading = false
                createEditItemDelegate?.createEditItemViewModelDidUpdateItem(itemContentType())
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }

    private func getKeysAndPassphrases(shareId: String) async throws -> KeysAndPassphrases {
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
        return .init(vaultKey: latestVaultKey,
                     vaultKeyPassphrase: vaultKeyPassphrase,
                     itemKey: latestItemKey,
                     itemKeyPassphrase: itemKeyPassphrase,
                     addressKey: userData.getAddressKey())
    }

    private func createItemRequest(shareId: String) async throws -> CreateItemRequest {
        let keysAndPassphrases = try await getKeysAndPassphrases(shareId: shareId)
        return try CreateItemRequest(vaultKey: keysAndPassphrases.vaultKey,
                                     vaultKeyPassphrase: keysAndPassphrases.vaultKeyPassphrase,
                                     itemKey: keysAndPassphrases.itemKey,
                                     itemKeyPassphrase: keysAndPassphrases.itemKeyPassphrase,
                                     addressKey: keysAndPassphrases.addressKey,
                                     itemContent: generateItemContent())
    }
}

private struct KeysAndPassphrases {
    let vaultKey: VaultKey
    let vaultKeyPassphrase: String
    let itemKey: ItemKey
    let itemKeyPassphrase: String
    let addressKey: AddressKey
}

struct AliasCreationInfo {
    let prefix: String
    let signedSuffix: String
    let mailboxIds: [Int]
}
