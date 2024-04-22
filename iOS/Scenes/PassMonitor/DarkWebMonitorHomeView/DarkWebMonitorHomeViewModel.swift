//
//
// DarkWebMonitorHomeViewModel.swift
// Proton Pass - Created on 16/04/2024.
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
import Core
import Entities
import Factory
import Foundation
import Macro
import UseCases

@MainActor
final class DarkWebMonitorHomeViewModel: ObservableObject, Sendable {
    @Published private(set) var userBreaches: UserBreaches
    @Published private(set) var customEmails: [CustomEmail]?
    @Published private(set) var suggestedEmail: [SuggestedEmail]?
    @Published private(set) var aliasInfos: [AliasMonitorInfo]?
    @Published private(set) var loading = false

    private let getCustomEmailSuggestion = resolve(\SharedUseCasesContainer.getCustomEmailSuggestion)
    private let getAllAliasMonitorInfos = resolve(\UseCasesContainer.getAllAliasMonitorInfos)
    private let updatesForDarkWebHome = resolve(\UseCasesContainer.updatesForDarkWebHome)
    private let addCustomEmailToMonitoring = resolve(\UseCasesContainer.addCustomEmailToMonitoring)
    private let removeEmailFromBreachMonitoring = resolve(\UseCasesContainer.removeEmailFromBreachMonitoring)
    private let getAllCustomEmails = resolve(\UseCasesContainer.getAllCustomEmails)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let logger = resolve(\SharedToolingContainer.logger)

    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?

    var noBreaches: Bool {
        noProtonEmailBreaches && noAliasBreaches
    }

    var mostBreachedProtonAddress: [ProtonAddress] {
        userBreaches.topTenBreachedAddresses
    }

    var mostBreachedAliases: [AliasMonitorInfo] {
        guard let aliasInfos else {
            return []
        }
        return aliasInfos.topTenBreachedAliases
    }

    var numberOFBreachedAlias: Int {
        aliasInfos?.filter { !$0.alias.item.skipHealthCheck && $0.alias.item.isBreached }.count ?? 0
    }

    var noProtonEmailBreaches: Bool {
        userBreaches.emailsCount == 0
    }

    var noAliasBreaches: Bool {
        numberOFBreachedAlias == 0
    }

    init(userBreaches: UserBreaches) {
        self.userBreaches = userBreaches
        customEmails = userBreaches.customEmails
        setUp()
    }

    func getCurrentLocalizedDateTime() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()

        // Set the date and time style
        dateFormatter.dateFormat = "MMM dd yyyy, HH:mm" // e.g., "Feb 14 2024, 09:41"

        // Set the locale to the current device's locale
        dateFormatter.locale = Locale.current

        // Optional: If you want the time to also adapt to the user's 24-hour or 12-hour format preference:
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .medium
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM dd yyyy, HH:mm")

        return dateFormatter.string(from: now)
    }

    func removeCustomMailFromMonitor(email: CustomEmail) {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                try await removeEmailFromBreachMonitoring(emailId: email.customEmailID)
            } catch {
                handle(error: error)
            }
        }
    }

    func addCustomEmail(email: String) async -> CustomEmail? {
        defer { loading = false }

        do {
            loading = true
            let customEmail = try await addCustomEmailToMonitoring(email: email)
            if let index = suggestedEmail?.firstIndex(where: { $0.email == email }) {
                suggestedEmail?.remove(at: index)
            }
            return customEmail
        } catch {
            handle(error: error)
        }
        return nil
    }
}

private extension DarkWebMonitorHomeViewModel {
    func setUp() {
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true

                async let currentCustomEmails = getAllCustomEmails()
                async let currentAliasInfos = getAllAliasMonitorInfos()
                async let currentSuggestedEmail = getCustomEmailSuggestion(breaches: userBreaches)

                let results = try await (customEmails: currentCustomEmails,
                                         suggestions: currentSuggestedEmail,
                                         alias: currentAliasInfos)
                customEmails = results.customEmails
                suggestedEmail = results.suggestions
                aliasInfos = results.alias
            } catch {
                handle(error: error)
            }
        }

        updatesForDarkWebHome()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] section in
                guard let self else {
                    return
                }
                switch section {
                case .aliases:
                    return
                case let .customEmails(updatedCustomEmails):
                    guard updatedCustomEmails != customEmails else {
                        return
                    }
                    customEmails = updatedCustomEmails
                case .protonAddresses:
                    return
                case .all:
                    return
                }
            }.store(in: &cancellables)
    }

    func handle(error: Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

extension String {
    var breachDate: String {
        let isoFormatter = DateFormatter()
//        isoFormatter.locale = Locale(identifier: "en_US_POSIX") // POSIX to ensure the format is interpreted
//        correctly
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        // Parse the date string into a Date object
        if let date = isoFormatter.date(from: self) {
            // Create another DateFormatter to output the date in the desired format
            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale.current // Change to specific locale if needed
            outputFormatter.dateFormat = "MMM d, yyyy"

            // Format the Date object into the desired date string
            return outputFormatter.string(from: date)
        } else {
            return ""
        }
    }
}
