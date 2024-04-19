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
import Client
import Combine
import Entities
import Factory
import Foundation
import UseCases

@MainActor
final class DarkWebMonitorHomeViewModel: ObservableObject, Sendable {
    @Published private(set) var userBreaches: UserBreaches
    // periphery:ignore
    @Published private(set) var customEmails: [CustomEmail]?
    @Published private(set) var suggestedEmail: [SuggestedEmail]?
    @Published private(set) var aliasInfos: [AliasMonitorInfo]?

    @Published private(set) var loading = false

    private let breachRepository = resolve(\RepositoryContainer.breachRepository)
    private let getCustomEmailSuggestion = resolve(\SharedUseCasesContainer.getCustomEmailSuggestion)
    private let getAllAliasMonitorInfos = resolve(\UseCasesContainer.getAllAliasMonitorInfos)
    private var cancellables = Set<AnyCancellable>()

    var noBreaches: Bool {
        noProtonEmailBreaches && noAliasBreaches
    }

    var mostBreachedProtonAddress: [ProtonAddress] {
        Array(userBreaches.addresses.filter { !$0.flags.isFlagActive(.skipHealthChecktest) }
            .sorted { $0.breachCounter > $1.breachCounter }.prefix(10))
    }

    var mostBreachedAliases: [AliasMonitorInfo] {
        guard let aliasInfos else {
            return []
        }
        return Array(aliasInfos.sorted {
            ($0.breaches?.count ?? Int.min) > ($1.breaches?.count ?? Int.min)
        }.filter(\.alias.item.skipHealthCheck).prefix(10))
    }

    var numberOFBreachedAlias: Int {
        aliasInfos?.filter(\.alias.item.skipHealthCheck).count ?? 0
    }

    var noProtonEmailBreaches: Bool {
        userBreaches.emailsCount == 0
    }

    var noAliasBreaches: Bool {
        numberOFBreachedAlias == 0
    }

    init(userBreaches: UserBreaches) {
        self.userBreaches = userBreaches
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
                try await breachRepository.removeEmailFromBreachMonitoring(emailId: email.customEmailID)
                customEmails = try await breachRepository.getAllCustomEmailForUser()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func addCustomEmail(email: String) async -> CustomEmail? {
        defer { loading = false }

        do {
            loading = true
            return try await breachRepository.addEmailToBreachMonitoring(email: email)
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
}

private extension DarkWebMonitorHomeViewModel {
    func setUp() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true

                async let currentCustomEmails = breachRepository.getAllCustomEmailForUser()
                async let currentAliasInfos = getAllAliasMonitorInfos()
                async let currentSuggestedEmail = getCustomEmailSuggestion(breaches: userBreaches)

                customEmails = try await breachRepository.getAllCustomEmailForUser()
                let results = try await (currentCustomEmails, currentSuggestedEmail, currentAliasInfos)
                customEmails = results.0
                suggestedEmail = results.1
                aliasInfos = results.2
            } catch {
                print(error.localizedDescription)
            }
        }

        breachRepository.updatedCustomEmails
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedCustomEmails in
                guard let self, updatedCustomEmails != customEmails else {
                    return
                }
                customEmails = updatedCustomEmails
            }.store(in: &cancellables)
    }
}

extension SuggestedEmail {
    var toCustomEmail: CustomEmail {
        CustomEmail(customEmailID: UUID().uuidString,
                    email: email,
                    verified: false,
                    breachCounter: 0,
                    flags: 0,
                    lastBreachedTime: 0)
    }
}
