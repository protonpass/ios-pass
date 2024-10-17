//
// LoginsWith2faViewModel.swift
// Proton Pass - Created on 16/10/2024.
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

import Entities
import Factory

@MainActor
final class LoginsWith2faViewModel {
    let items: [ItemUiModel]

    @LazyInjected(\SharedRepositoryContainer.itemRepository)
    private var itemRepository

    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var router

    init(items: [ItemUiModel]) {
        self.items = items
    }

    func select(_ item: any ItemIdentifiable) {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                             itemId: item.itemId) {
                    router.present(for: .itemDetail(itemContent, automaticDisplay: false))
                } else {
                    throw PassError.itemNotFound(item)
                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
