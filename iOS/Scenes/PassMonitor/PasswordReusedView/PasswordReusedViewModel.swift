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

import Entities
import Factory
import Foundation

@MainActor
final class PasswordReusedViewModel: ObservableObject, Sendable {
    @Published private(set) var reusedItems: [ItemContent] = []
    @Published private(set) var loading = false

    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let itemContent: ItemContent

    var title: String {
        itemContent.loginItem?.password.transformString(withChar: "•") ?? "Unknown"
    }

    init(itemContent: ItemContent) {
        self.itemContent = itemContent

        fetchSimilarPasswordItems()
    }

    func itemAction(item: ItemContent) {
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
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

extension String {
    func transformString(withChar newChar: Character) -> String {
        guard count > 2,
              let firstChar = first,
              let lastChar = last else { return self } // Return the original string if it's too short

        let startIndex = index(after: startIndex)
        let endIndex = index(before: endIndex)
        let middleCount = distance(from: startIndex, to: endIndex)

        let middleReplacement = String(repeating: newChar, count: middleCount)
        return "\(firstChar)\(middleReplacement)\(lastChar)"
    }
}
