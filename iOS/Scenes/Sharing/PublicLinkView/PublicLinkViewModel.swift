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
import Foundation
import Macro

enum SecureLinkExpiration: Sendable, Hashable, Identifiable {
    case hour(Int)
    case day(Int)

    var id: Int { seconds }

    var title: String {
        switch self {
        case let .hour(hour):
            #localized("%lld hour(s)", hour)
        case let .day(day):
            #localized("%lld day(s)", day)
        }
    }

    var seconds: Int {
        switch self {
        case let .hour(hour):
            hour * 3_600
        case let .day(day):
            day * 24 * 3_600
        }
    }

    static var supportedExpirations: [SecureLinkExpiration] {
        [.hour(1), .day(1), .day(7), .day(14), .day(30)]
    }
}

@MainActor
final class PublicLinkViewModel: ObservableObject, Sendable {
    @Published private(set) var link: SharedPublicLink?
    @Published var selectedExpiration: SecureLinkExpiration = .day(7)
    @Published var loading = false
    @Published var viewCount = 0

    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    let createItemSharingPublicLink = resolve(\SharedUseCasesContainer.createItemSharingPublicLink)

    let itemContent: ItemContent

    init(itemContent: ItemContent) {
        self.itemContent = itemContent
    }

    func createLink() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                let maxReadCount = viewCount == 0 ? nil : viewCount
                let result = try await createItemSharingPublicLink(item: itemContent,
                                                                   expirationTime: selectedExpiration.seconds,
                                                                   maxReadCount: maxReadCount)
                link = result
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func copyLink() {
        guard let link else {
            return
        }
        router.action(.copyToClipboard(text: link.url, message: #localized("Link copied")))
    }
}

extension SharedPublicLink {
    var relativeTimeRemaining: String? {
        guard let expirationTime else {
            return nil
        }
        let expirationDate = Date(timeIntervalSince1970: Double(expirationTime))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let currentDate = Date()
        let relativeTime = formatter.localizedString(for: expirationDate, relativeTo: currentDate)

        return relativeTime
    }
}
