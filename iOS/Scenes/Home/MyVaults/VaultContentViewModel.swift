//
// VaultContentViewModel.swift
// Proton Pass - Created on 21/07/2022.
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
import ProtonCore_UIFoundations
import UIComponents
import UIKit

protocol VaultContentViewModelDelegate: AnyObject {
    func vaultContentViewModelWantsToToggleSidebar()
    func vaultContentViewModelWantsToSearch()
    func vaultContentViewModelWantsToCreateNewItem()
    func vaultContentViewModelWantsToCreateNewVault()
    func vaultContentViewModelWantsToShowItemDetail(itemContent: ItemContent)
    func vaultContentViewModelBeginsLoading()
    func vaultContentViewModelStopsLoading()
    func vaultContentViewModelDidFailWithError(error: Error)
}

final class VaultContentViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    var selectedVault: VaultProtocol? { vaultSelection.selectedVault }
    var vaults: [VaultProtocol] { vaultSelection.vaults }

    @Published private var isLoading = false
    @Published private var error: Error?

    @Published private(set) var partialItemContents = [PartialItemContent]()

    private let userData: UserData
    private let vaultSelection: VaultSelection
    private let shareRepository: ShareRepositoryProtocol
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol
    private let shareKeysRepository: ShareKeysRepositoryProtocol
    private let publicKeyRepository: PublicKeyRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: VaultContentViewModelDelegate?

    init(userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         publicKeyRepository: PublicKeyRepositoryProtocol) {
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.itemRevisionRepository = itemRevisionRepository
        self.shareKeysRepository = shareKeysRepository
        self.publicKeyRepository = publicKeyRepository

        vaultSelection.objectWillChange
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.vaultContentViewModelBeginsLoading()
                } else {
                    self.delegate?.vaultContentViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.vaultContentViewModelDidFailWithError(error: error)
                }
            }
            .store(in: &cancellables)
    }

    func update(selectedVault: VaultProtocol?) {
        vaultSelection.update(selectedVault: selectedVault)
    }

    func fetchItems(forceRefresh: Bool = false) {
        guard let shareId = selectedVault?.shareId else { return }
        Task { @MainActor in
            do {
                let itemRevisions = try await itemRevisionRepository.getItemRevisions(forceRefresh: forceRefresh,
                                                                                      shareId: shareId,
                                                                                      state: .active)
                try await decrypt(itemRevisions: itemRevisions,
                                  shareId: shareId,
                                  forceRefresh: forceRefresh)
            } catch {
                self.error = error
            }
        }
    }

    private func decrypt(itemRevisions: [ItemRevision],
                         shareId: String,
                         forceRefresh: Bool) async throws {
        let (share, shareKeys) = try await getShareAndKeys(shareId: shareId, forceRefresh: forceRefresh)

        var partialItemContents = [PartialItemContent]()
        for itemRevision in itemRevisions {
            let publicKeys =
            try await publicKeyRepository.getPublicKeys(email: itemRevision.signatureEmail)
            let verifyKeys = publicKeys.map { $0.value }
            let partialItemContent =
            try itemRevision.getPartialContent(userData: userData,
                                               share: share,
                                               vaultKeys: shareKeys.vaultKeys,
                                               itemKeys: shareKeys.itemKeys,
                                               verifyKeys: verifyKeys)
            partialItemContents.append(partialItemContent)
        }
        self.partialItemContents = partialItemContents
    }

    func selectItem(_ partialItemContent: PartialItemContent) {
        Task { @MainActor in
            do {
                if let itemRevision =
                    try await itemRevisionRepository.getItemRevision(shareId: partialItemContent.shareId,
                                                                     itemId: partialItemContent.itemId) {
                    let (share, shareKeys) = try await getShareAndKeys(shareId: partialItemContent.shareId,
                                                                       forceRefresh: false)
                    let publicKeys =
                    try await publicKeyRepository.getPublicKeys(email: itemRevision.signatureEmail)
                    let verifyKeys = publicKeys.map { $0.value }
                    let itemContent = try itemRevision.getContent(userData: userData,
                                                                  share: share,
                                                                  vaultKeys: shareKeys.vaultKeys,
                                                                  itemKeys: shareKeys.itemKeys,
                                                                  verifyKeys: verifyKeys)
                    delegate?.vaultContentViewModelWantsToShowItemDetail(itemContent: itemContent)
                }
            } catch {
                self.error = error
            }
        }
    }

    private func getShareAndKeys(shareId: String,
                                 forceRefresh: Bool) async throws -> (Share, ShareKeys) {
        let share = try await shareRepository.getShare(shareId: shareId)
        let shareKeys = try await shareKeysRepository.getShareKeys(shareId: shareId,
                                                                   page: 0,
                                                                   pageSize: kDefaultPageSize,
                                                                   forceRefresh: forceRefresh)
        return (share, shareKeys)
    }

    func trash(_ partialItemContent: PartialItemContent) {
        Task { @MainActor in
            do {
                if let itemRevision =
                    try await itemRevisionRepository.getItemRevision(shareId: partialItemContent.shareId,
                                                                     itemId: partialItemContent.itemId) {
                    isLoading = true
                    let request = TrashItemsRequest(items: [itemRevision.itemToBeTrashed()])
                    try await itemRevisionRepository.trashItem(request: request,
                                                               shareId: partialItemContent.shareId)
                    isLoading = false
                    partialItemContents.removeAll(where: { $0.itemId == partialItemContent.itemId })
                }
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }
}

// MARK: - Actions
extension VaultContentViewModel {
    func toggleSidebarAction() {
        delegate?.vaultContentViewModelWantsToToggleSidebar()
    }

    func searchAction() {
        delegate?.vaultContentViewModelWantsToSearch()
    }

    func createItemAction() {
        delegate?.vaultContentViewModelWantsToCreateNewItem()
    }

    func createVaultAction() {
        delegate?.vaultContentViewModelWantsToCreateNewVault()
    }
}
