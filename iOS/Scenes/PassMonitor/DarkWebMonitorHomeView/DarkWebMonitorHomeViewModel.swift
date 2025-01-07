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
import UseCases

@MainActor
final class DarkWebMonitorHomeViewModel: ObservableObject, Sendable {
    @Published private(set) var access: Access?
    @Published private(set) var userBreaches: UserBreaches
    @Published private(set) var aliasBreachesState: FetchableObject<[AliasMonitorInfo]> = .fetching
    @Published private(set) var customEmailsState: FetchableObject<[CustomEmail]> = .fetching
    @Published private(set) var suggestedEmailsState: FetchableObject<[SuggestedEmail]> = .fetching
    @Published private(set) var updatingStateOfCustomEmail = false

    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let getCustomEmailSuggestion = resolve(\SharedUseCasesContainer.getCustomEmailSuggestion)
    private let getAllAliasMonitorInfos = resolve(\UseCasesContainer.getAllAliasMonitorInfos)
    private let addCustomEmailToMonitoring = resolve(\UseCasesContainer.addCustomEmailToMonitoring)
    private let removeEmailFromBreachMonitoring = resolve(\UseCasesContainer.removeEmailFromBreachMonitoring)
    private let getAllCustomEmails = resolve(\UseCasesContainer.getAllCustomEmails)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let logger = resolve(\SharedToolingContainer.logger)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    private var cancellables = Set<AnyCancellable>()
    private var fetchAliasBreachesTask: Task<Void, Never>?
    private var fetchCustomEmailsTask: Task<Void, Never>?
    private var fetchSuggestedEmailsTask: Task<Void, Never>?

    init(userBreaches: UserBreaches) {
        access = accessRepository.access.value?.access
        self.userBreaches = userBreaches
        customEmailsState = .fetched(userBreaches.customEmails)
        setUp()
        fetchAliasBreaches()
        fetchCustomEmails()
        fetchSuggestedEmails()
    }

    func refresh() async throws {
        userBreaches = try await passMonitorRepository.refreshUserBreaches()
        customEmailsState = .fetched(userBreaches.customEmails)
        fetchAliasBreaches()
        fetchCustomEmails()
        fetchSuggestedEmails()
    }
}

extension DarkWebMonitorHomeViewModel {
    func fetchAliasBreaches() {
        fetchAliasBreachesTask?.cancel()
        fetchAliasBreachesTask = Task { [weak self] in
            guard let self else { return }
            do {
                try Task.checkCancellation()
                if aliasBreachesState.isError {
                    aliasBreachesState = .fetching
                }
                let userId = try await userManager.getActiveUserId()
                let infos = try await getAllAliasMonitorInfos(userId: userId)
                aliasBreachesState = .fetched(infos)
            } catch {
                aliasBreachesState = .error(error)
            }
        }
    }

    func fetchCustomEmails() {
        fetchCustomEmailsTask?.cancel()
        fetchCustomEmailsTask = Task { [weak self] in
            guard let self else { return }
            do {
                try Task.checkCancellation()
                if customEmailsState.isError {
                    customEmailsState = .fetching
                }
                let emails = try await getAllCustomEmails()
                customEmailsState = .fetched(emails)
            } catch {
                customEmailsState = .error(error)
            }
        }
    }

    func fetchSuggestedEmails() {
        fetchSuggestedEmailsTask?.cancel()
        fetchSuggestedEmailsTask = Task { [weak self] in
            guard let self else { return }
            do {
                try Task.checkCancellation()
                if suggestedEmailsState.isError {
                    suggestedEmailsState = .fetching
                }
                let customEmails = customEmailsState.fetchedObject ?? []
                let userId = try await userManager.getActiveUserId()
                let emails = try await getCustomEmailSuggestion(userId: userId,
                                                                monitoredCustomEmails: customEmails,
                                                                protonAddresses: userBreaches.addresses)
                suggestedEmailsState = .fetched(emails)
            } catch {
                suggestedEmailsState = .error(error)
            }
        }
    }

    func removeCustomMailFromMonitor(email: CustomEmail) {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { updatingStateOfCustomEmail = false }
            do {
                updatingStateOfCustomEmail = true
                try await removeEmailFromBreachMonitoring(email: email)
            } catch {
                handle(error: error)
            }
        }
    }

    func addCustomEmail(email: String) async -> CustomEmail? {
        defer { updatingStateOfCustomEmail = false }
        do {
            updatingStateOfCustomEmail = true
            return try await addCustomEmailToMonitoring(email: email)
        } catch {
            handle(error: error)
            return nil
        }
    }
}

private extension DarkWebMonitorHomeViewModel {
    func setUp() {
        passMonitorRepository.darkWebDataSectionUpdate
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] section in
                guard let self else {
                    return
                }
                switch section {
                case let .aliases(newValue):
                    aliasBreachesState = .fetched(newValue)
                case let .customEmails(newValue):
                    customEmailsState = .fetched(newValue)
                    fetchSuggestedEmails()
                case let .protonAddresses(updatedUserBreaches):
                    userBreaches = updatedUserBreaches
                }
            }.store(in: &cancellables)

        accessRepository.access
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self else { return }
                access = newValue?.access
            }
            .store(in: &cancellables)
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
