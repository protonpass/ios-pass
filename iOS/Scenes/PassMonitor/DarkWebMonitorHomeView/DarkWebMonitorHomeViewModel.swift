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
    @Published private(set) var access: Access?
    @Published private(set) var userBreaches: UserBreaches
    @Published private(set) var customEmails: [CustomEmail]
    @Published private(set) var suggestedEmail: [SuggestedEmail]?
    @Published private(set) var aliasInfos: [AliasMonitorInfo]?

    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let getCustomEmailSuggestion = resolve(\SharedUseCasesContainer.getCustomEmailSuggestion)
    private let getAllAliasMonitorInfos = resolve(\UseCasesContainer.getAllAliasMonitorInfos)
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

    var numberOfBreachedAlias: Int {
        aliasInfos?.filter { !$0.alias.item.skipHealthCheck && $0.alias.item.isBreached }.count ?? 0
    }

    var noProtonEmailBreaches: Bool {
        userBreaches.emailsCount == 0
    }

    var noAliasBreaches: Bool {
        numberOfBreachedAlias == 0
    }

    init(userBreaches: UserBreaches) {
        access = accessRepository.access.value
        self.userBreaches = userBreaches
        customEmails = userBreaches.customEmails
        setUp()
    }

    func getCurrentLocalizedDateTime() -> String {
        let dateFormatter = DateFormatter(format: "MMM dd yyyy, HH:mm")
        return dateFormatter.string(from: .now)
    }

    func removeCustomMailFromMonitor(email: CustomEmail) {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                try await removeEmailFromBreachMonitoring(email: email)
            } catch {
                handle(error: error)
            }
        }
    }

    func addCustomEmail(email: String) async -> CustomEmail? {
        defer { router.display(element: .globalLoading(shouldShow: false)) }

        do {
            router.display(element: .globalLoading(shouldShow: true))
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

    func breachSubtitle(numberOfBreaches: Int) -> String {
        numberOfBreaches == 0 ? #localized("No breaches detected") :
            #localized("Found in %lld breaches", numberOfBreaches)
    }
}

private extension DarkWebMonitorHomeViewModel {
    func setUp() {
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
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

        passMonitorRepository.darkWebDataSectionUpdate
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] section in
                guard let self else {
                    return
                }
                switch section {
                case let .aliases(updatedAliasInfos):
                    aliasInfos = updatedAliasInfos
                case let .customEmails(updatedCustomEmails):
                    customEmails = updatedCustomEmails
                    reloadEmailSuggestion()
                case let .protonAddresses(updatedUserBreaches):
                    userBreaches = updatedUserBreaches
                }
            }.store(in: &cancellables)

        accessRepository.access
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                access = newValue
            }
            .store(in: &cancellables)
    }

    func reloadEmailSuggestion() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                suggestedEmail = try await getCustomEmailSuggestion(breaches: userBreaches)
            } catch {
                handle(error: error)
            }
        }
    }

    func handle(error: Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
