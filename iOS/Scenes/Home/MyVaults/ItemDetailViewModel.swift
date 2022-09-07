//
// ItemDetailViewModel.swift
// Proton Pass - Created on 07/09/2022.
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

protocol ItemDetailViewModelDelegate: AnyObject {
    func itemDetailViewModelBeginsLoading()
    func itemDetailViewModelStopsLoading()
    func itemDetailViewModelDidFailWithError(error: Error)
}

enum ItemDetailViewModelError: Error {
    case itemRevisionNotFound(shareId: String, itemId: String)
}

final class ItemDetailViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    let itemContent: ItemContent
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: ItemDetailViewModelDelegate?

    init(itemContent: ItemContent,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        self.itemContent = itemContent
        self.itemRevisionRepository = itemRevisionRepository

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.itemDetailViewModelBeginsLoading()
                } else {
                    self.delegate?.itemDetailViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.itemDetailViewModelDidFailWithError(error: error)
                }
            }
            .store(in: &cancellables)
    }
}
