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

struct TimeOption: Identifiable, Hashable {
    var id: Int { seconds }
    let label: String
    let seconds: Int

    static var `default`: TimeOption {
        TimeOption(label: #localized("%lld Day", 7), seconds: 7 * 86_400)
    }

    static var secondsInHour: Int {
        3_600
    }

    static var secondsInDay: Int {
        86_400
    }
}

@MainActor
final class PublicLinkViewModel: ObservableObject, Sendable {
    @Published private(set) var link: SharedPublicLink?
    @Published var selectedTime: TimeOption = .default
    @Published var loading = false
    @Published var addNumberOfReads = false
    @Published var maxNumber = ""

    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    let createItemSharingPublicLink = resolve(\SharedUseCasesContainer.createItemSharingPublicLink)

    let timeOptions: [TimeOption] = TimeOption.generateTimeOptions
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
                let result = try await createItemSharingPublicLink(item: itemContent,
                                                                   expirationTime: selectedTime.seconds,
                                                                   maxReadCount: maxNumber.maxRead)
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

extension TimeOption {
    static var generateTimeOptions: [TimeOption] {
        var options = [TimeOption]()

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full

        // Add 30 minutes
        if let formattedLabel = formatter.string(from: TimeInterval(TimeOption.secondsInHour / 2)) {
            options.append(TimeOption(label: formattedLabel, seconds: 1_800))
        }

        // Add hours from 1 to 12
        for hour in 1...12 {
            let label = #localized("%lld Hour", hour)
            options.append(TimeOption(label: label, seconds: hour * TimeOption.secondsInHour))
        }

        // Add days from 1 to 30
        for day in 1...30 {
            let label = #localized("%lld Day", day)
            options.append(TimeOption(label: label, seconds: day * TimeOption.secondsInDay))
        }

        return options
    }
}

private extension String {
    var maxRead: Int? {
        guard !isEmpty, let number = Int(self) else {
            return nil
        }
        return number
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
