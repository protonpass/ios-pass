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

protocol BaseCreateItemViewModelDelegate: AnyObject {
    func createItemViewModelBeginsLoading()
    func createItemViewModelStopsLoading()
    func createItemViewModelDidFailWithError(_ error: Error)
    func createItemViewModelDidCreateItem(_ itemContentType: ItemContentType)
}

class BaseCreateItemViewModel {
    @Published var isLoading = false
    @Published var error: Error?

    var cancellables = Set<AnyCancellable>()
    weak var delegate: BaseCreateItemViewModelDelegate?

    let shareId: String
    let addressKey: AddressKey
    let shareKeysRepository: ShareKeysRepositoryProtocol
    let itemRevisionRepository: ItemRevisionRepositoryProtocol

    init(shareId: String,
         addressKey: AddressKey,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        self.shareId = shareId
        self.addressKey = addressKey
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
//                isLoading = true
//                let itemContent = generateItemContent()
//
//                let (latestVaultKey, latestItemKey) =
//                try await shareKeysRepository.getLatestVaultItemKey(shareId: shareId, forceRefresh: false)
//                let request = try CreateItemRequest(vaultKey: latestVaultKey,
//                                                    itemKey: latestItemKey,
//                                                    addressKey: addressKey,
//                                                    itemContent: itemContent)
//                try await itemRevisionRepository.createItem(request: request, shareId: shareId)
                delegate?.createItemViewModelDidCreateItem(itemContentType())
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}
