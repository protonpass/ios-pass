//
// BaseItemDetailViewModel.swift
// Proton Pass - Created on 08/09/2022.
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

protocol ItemDetailViewModelDelegate: AnyObject {
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent)
    func itemDetailViewModelDidTrashItem(_ type: ItemContentType)
}

class BaseItemDetailViewModel: BaseViewModel {
    @Published var isTrashed = false

    private let itemRepository: ItemRepositoryProtocol
    let itemContent: ItemContent

    weak var itemDetailDelegate: ItemDetailViewModelDelegate?

    init(itemContent: ItemContent,
         itemRepository: ItemRepositoryProtocol) {
        self.itemContent = itemContent
        self.itemRepository = itemRepository
        super.init()
        bindValues()

        $isTrashed
            .sink { [weak self] isTrashed in
                guard let self = self else { return }
                if isTrashed {
                    self.itemDetailDelegate?.itemDetailViewModelDidTrashItem(itemContent.contentData.type)
                }
            }
            .store(in: &cancellables)
    }

    /// To be overidden by subclasses
    func bindValues() {}

    func edit() {
        itemDetailDelegate?.itemDetailViewModelWantsToEditItem(itemContent)
    }

    func trash() {
        Task { @MainActor in
            do {
                if let item = try await itemRepository.getItem(shareId: itemContent.shareId,
                                                               itemId: itemContent.itemId) {
                    isLoading = true
                    try await itemRepository.trashItems([item])
                    isLoading = false
                    isTrashed = true
                }
            } catch {
                self.error = error
            }
        }
    }
}
