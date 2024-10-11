//
// BaseItemDetailViewModel.swift
// Proton Pass - Created on 09/10/2024.
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
import Foundation

@MainActor
class BaseItemDetailViewModel: ObservableObject {
    @Published private(set) var isFreeUser = false

    let item: SelectedItem
    let selectedTextStream: SelectedTextStream
    let customFieldUiModels: [CustomFieldUiModel]

    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedServiceContainer.upgradeChecker) var upgradeChecker

    var type: ItemContentType {
        item.content.type
    }

    init(item: SelectedItem, selectedTextStream: SelectedTextStream) {
        self.item = item
        self.selectedTextStream = selectedTextStream
        customFieldUiModels = item.content.customFields.map { .init(customField: $0) }
        bindValues()
    }

    /// To be overidden by subclasses
    func bindValues() {}
}

private extension BaseItemDetailViewModel {
    func checkIfFreeUser() {
        Task { [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
            } catch {
                handle(error)
            }
        }
    }
}

extension BaseItemDetailViewModel {
    func autofill(_ text: String) {
        selectedTextStream.send(.init(value: text, item: item.content))
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }
}
