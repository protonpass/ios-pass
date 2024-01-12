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

// This enum must have exact name of variables contained in ItemContent and it sub classes
enum ItemElement: String {
    case name
    case note

    // login
    case password
    case username
    case urls
    case website
    case customFields

    // card
    case cardholderName
    case verificationNumber
    case expirationDate
    case securityCode
    case pin
    case type

    case alias
    case forwardAddress
}

extension ItemContent: Diffable {}
extension Item: Diffable {}
extension ItemContentData: Diffable {}
extension LogInItemData: Diffable {}
extension CreditCardData: Diffable {}

protocol Diffable {
    associatedtype DiffableType: Diffable
    func differences(from other: DiffableType) -> [String]
}

extension Diffable {
    func differences(from other: Self) -> [String] {
        var differences = [String]()
        let mirror1 = Mirror(reflecting: self)
        let mirror2 = Mirror(reflecting: other)

        for (label, value1) in mirror1.children {
            guard let label else { continue }
            if let value2 = mirror2.children.first(where: { $0.label == label })?.value {
                if let subDiffable1 = value1 as? Self,
                   let subDiffable2 = value2 as? Self {
                    let subDiffs = subDiffable1.differences(from: subDiffable2)
                    differences.append(contentsOf: subDiffs.map { "\($0)" })
                } else if !"\(value1)".elementsEqual("\(value2)") {
                    differences.append("\(label)")
                }
            }
        }

        return differences
    }
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

    private let differences: [String]

    init(currentItem: ItemContent,
         revision: ItemContent) {
        self.currentItem = currentItem
        self.revision = revision
        selectedItem = revision
        differences = currentItem.differences(from: revision)
        setUp()
    }

    func isDifferent(for element: ItemElement) -> Bool {
        differences.contains(element.rawValue)
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
