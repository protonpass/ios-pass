//
// ItemCountViewModel.swift
// Proton Pass - Created on 30/03/2023.
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

import Client
import Core

enum ItemCountViewModelState {
    case loading
    case loaded(ItemCount)
    case error(Error)
}

final class ItemCountViewModel: ObservableObject {
    @Published private(set) var state = ItemCountViewModelState.loading

    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger

    init(itemRepository: ItemRepositoryProtocol, logManager: LogManager) {
        self.itemRepository = itemRepository
        self.logger = .init(manager: logManager)
        self.refresh()
    }

    func refresh() {
        Task { @MainActor in
            do {
                state = .loading
                let activeItems = try await itemRepository.getItems(state: .active)
                let trashedItems = try await itemRepository.getItems(state: .trashed)
                let symmetricKey = itemRepository.symmetricKey
                let items = try (activeItems + trashedItems).map { try $0.toItemUiModel(symmetricKey) }
                let itemCount = ItemCount(items: items)
                state = .loaded(itemCount)
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }
}
