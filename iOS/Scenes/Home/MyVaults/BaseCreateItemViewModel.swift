//
// BaseCreateItemViewModel.swift
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
import Combine
import Core
import ProtonCore_Login

class BaseCreateItemViewModel: BaseViewModel {
    @Published var isLoading = false
    @Published var error: Error?

    var cancellables = Set<AnyCancellable>()

    let shareId: String
    let userData: UserData
    let shareRepository: ShareRepositoryProtocol
    let shareKeysRepository: ShareKeysRepositoryProtocol
    let itemRevisionRepository: ItemRevisionRepositoryProtocol

    var onCreatedItem: ((ItemContentType) -> Void)?

    init(shareId: String,
         userData: UserData,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        self.shareId = shareId
        self.userData = userData
        self.shareRepository = shareRepository
        self.shareKeysRepository = shareKeysRepository
        self.itemRevisionRepository = itemRevisionRepository
    }

    // swiftlint:disable:next unavailable_function
    func itemContentType() -> ItemContentType {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:disable:next unavailable_function
    func generateItemContent() -> ItemContentProtobuf {
        fatalError("Must be overridden by subclasses")
    }

    func createItem() {
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
                isLoading = false
                self.error = error
            }
        }
    }
}
