//
//
// PublicLinkViewModel.swift
// Proton Pass - Created on 16/05/2024.
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
import Macro

struct TimeOption: Identifiable, Hashable {
    var id: Int { seconds }
    let label: String
    let seconds: Int

    static var `default`: TimeOption {
        TimeOption(label: #localized("%lld Day", 7), seconds: 7 * 86_400)
    }
}

@MainActor
final class PublicLinkViewModel: ObservableObject, Sendable {
    @Published private(set) var link: String?
    @Published var selectedTime: TimeOption = .default
    @Published var loading = false

    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    let createItemSharingPublicLink = resolve(\SharedUseCasesContainer.createItemSharingPublicLink)

    let timeOptions: [TimeOption] = TimeOption.generateTimeOptions
    let itemContent: ItemContent

    init(itemContent: ItemContent) {
        self.itemContent = itemContent
        setUp()
    }

    func createLink() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                let result = try await createItemSharingPublicLink(item: itemContent,
                                                                   expirationTime: selectedTime.seconds)
                link = result.url
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func copyLink() {
        guard let link else {
            return
        }
        router.action(.copyToClipboard(text: link, message: #localized("Link copied")))
    }
}

private extension PublicLinkViewModel {
    func setUp() {}
}

extension TimeOption {
    static var generateTimeOptions: [TimeOption] {
        var options = [TimeOption]()

        // Add 30 minutes
        options.append(TimeOption(label: "30 Minutes", seconds: 1_800))

        // Add hours from 1 to 12
        for hour in 1...12 {
            let label = #localized("%lld Hour", hour) // "\(hour) Hour" + (hour > 1 ? "s" : "")
            options.append(TimeOption(label: label, seconds: hour * 3_600))
        }

        // Add days from 1 to 30
        for day in 1...30 {
            let label = #localized("%lld Day", day) // "\(day) Day" + (day > 1 ? "s" : "")
            options.append(TimeOption(label: label, seconds: day * 86_400))
        }

        return options
    }
}
