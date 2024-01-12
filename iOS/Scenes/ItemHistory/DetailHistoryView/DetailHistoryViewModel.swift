//
//
// DetailHistoryViewModel.swift
// Proton Pass - Created on 11/01/2024.
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
//

import Combine
import Entities
import Factory
import Foundation

enum ItemElement {
    case name
    case note
    case password
    case username
    case website
    case customFields
    case cardHolder
    case cardNumber
    case expirationDate
    case securityCode
    case pin
    case alias
    case forwardAddress
}

@MainActor
final class DetailHistoryViewModel: ObservableObject, Sendable {
    @Published var selectedItemIndex = 0
    @Published private(set) var selectedItem: ItemContent
    @Published private(set) var restoringItem = false

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private var cancellables = Set<AnyCancellable>()

    let currentItem: ItemContent
    let revision: ItemContent

    init(currentItem: ItemContent,
         revision: ItemContent) {
        self.currentItem = currentItem
        self.revision = revision
        selectedItem = revision
        setUp()
    }

    func isEqual(for element: ItemElement) -> Bool {
        switch element {
        case .name:
            currentItem.name == revision.name
        case .note:
            currentItem.note == revision.note
        case .password:
            false
        case .username:
            false
        case .website:
            false

        case .customFields:
            false

        case .cardHolder:
            false

        case .cardNumber:
            false

        case .expirationDate:
            false

        case .securityCode:
            false

        case .pin:
            false

        case .alias:
            false

        case .forwardAddress:
            false
        }
    }

    func restore() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                restoringItem = false
            }
            restoringItem = true
            do {
                let protobuff = ItemContentProtobuf(name: revision.name,
                                                    note: revision.note,
                                                    itemUuid: revision.itemUuid,
                                                    data: revision.contentData,
                                                    customFields: revision.customFields)
                try await itemRepository.updateItem(oldItem: currentItem.item,
                                                    newItemContent: protobuff,
                                                    shareId: currentItem.shareId)
                router.present(for: .restoreHistory)
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

private extension DetailHistoryViewModel {
    func setUp() {
        $selectedItemIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self else {
                    return
                }
                selectedItem = index == 0 ? revision : currentItem
            }
            .store(in: &cancellables)
    }
}
