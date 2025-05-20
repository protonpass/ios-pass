//
//
// PasswordReusedViewModel.swift
// Proton Pass - Created on 27/03/2024.
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

import Core
import Entities
import FactoryKit
import Foundation

@MainActor
final class PasswordReusedViewModel: ObservableObject {
    @Published private(set) var reusedItems: [ItemContent] = []
    @Published private(set) var loading = false

    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let itemContent: ItemContent

    var title: String {
        itemContent.loginItem?.password.replaceAllCharsExceptFirstAndLast(withChar: "•") ?? "Unknown"
    }

    init(itemContent: ItemContent) {
        self.itemContent = itemContent

        fetchSimilarPasswordItems()
    }

    func viewDetail(of item: ItemContent) {
        router.present(for: .itemDetail(item, automaticDisplay: false, showSecurityIssues: true))
    }
}

private extension PasswordReusedViewModel {
    func fetchSimilarPasswordItems() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                loading = false
            }
            do {
                loading = true
                reusedItems = try await passMonitorRepository.getItemsWithSamePassword(item: itemContent)
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
