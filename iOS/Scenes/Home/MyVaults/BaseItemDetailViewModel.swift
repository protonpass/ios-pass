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
import Combine

protocol BaseItemDetailViewModelDelegate: AnyObject {
    func baseItemDetailViewModelBeginsLoading()
    func baseItemDetailViewModelStopsLoading()
    func baseItemDetailViewModelDidFinishTrashing(_ itemContentType: ItemContentType)
    func baseItemDetailViewModelDidFailWithError(error: Error)
}

class BaseItemDetailViewModel {
    @Published private var isLoading = false
    @Published private var error: Error?
    @Published var isTrashed = false

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: BaseItemDetailViewModelDelegate?

    private let itemContent: ItemContent
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol

    init(itemContent: ItemContent,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        self.itemContent = itemContent
        self.itemRevisionRepository = itemRevisionRepository

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.baseItemDetailViewModelBeginsLoading()
                } else {
                    self.delegate?.baseItemDetailViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.baseItemDetailViewModelDidFailWithError(error: error)
                }
            }
            .store(in: &cancellables)

        $isTrashed
            .sink { [weak self] isTrashed in
                guard let self = self else { return }
                if isTrashed {
                    self.delegate?.baseItemDetailViewModelDidFinishTrashing(itemContent.contentData.type)
                }
            }
            .store(in: &cancellables)
    }

    func trashAction() {
        Task { @MainActor in
            do {
                if let itemRevision =
                    try await itemRevisionRepository.getItemRevision(shareId: itemContent.shareId,
                                                                     itemId: itemContent.itemId) {
                    isLoading = true
                    let request = TrashItemsRequest(items: [itemRevision.itemToBeTrashed()])
                    try await itemRevisionRepository.trashItem(request: request,
                                                               shareId: itemContent.shareId)
                    isLoading = false
                    isTrashed = true
                }
            } catch {
                self.error = error
            }
        }
    }
}
