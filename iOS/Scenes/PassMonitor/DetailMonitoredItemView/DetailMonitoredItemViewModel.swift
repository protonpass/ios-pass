//
//
// DetailMonitoredItemViewModel.swift
// Proton Pass - Created on 23/04/2024.
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

@MainActor
final class DetailMonitoredItemViewModel: ObservableObject, Sendable {
    @Published private(set) var numberOfBreaches: Int?
    @Published private(set) var email: String?
    @Published private(set) var unresolvedBreaches: [Breach]?
    @Published private(set) var resolvedBreaches: [Breach]?
    @Published private(set) var linkedItems: [ItemUiModel]?
    @Published private(set) var shouldDismiss = false

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let getItemLinkedToBreach = resolve(\SharedUseCasesContainer.getItemLinkedToBreach)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let toggleMonitoringForAlias = resolve(\UseCasesContainer.toggleMonitoringForAlias)
    private let toggleMonitoringForCustomEmail = resolve(\UseCasesContainer.toggleMonitoringForCustomEmail)
    private let toggleMonitoringForProtonAddress = resolve(\UseCasesContainer.toggleMonitoringForProtonAddress)

    var isFullyResolved: Bool {
        unresolvedBreaches?.isEmpty ?? true
    }

    var isMonitored: Bool {
        switch infos {
        case let .alias(aliasInfos):
            !aliasInfos.alias.item.skipHealthCheck
        case let .customEmail(email):
            !email.flags.isFlagActive(.skipHealthCheckOrMonitoring)
        case let .protonAddress(address):
            !address.flags.isFlagActive(.skipHealthCheckOrMonitoring)
        }
    }

    private let infos: BreachDetailsInfo

    init(infos: BreachDetailsInfo) {
        self.infos = infos
        setUp()
    }

    func markAsResolved() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                switch infos {
                case let .alias(aliasInfos):
                    try await passMonitorRepository.markAliasAsResolved(sharedId: aliasInfos.alias.shareId,
                                                                        itemId: aliasInfos.alias.itemId)
                    try await fetchAliasInfos(alias: aliasInfos.alias)
                case let .customEmail(email):
                    _ = try await passMonitorRepository.markCustomEmailAsResolved(email: email)
                    try await fetchCustomEmailInfos(email: email)
                case let .protonAddress(address):
                    try await passMonitorRepository.markProtonAddressAsResolved(address: address)
                    try await fetchAddressInfos(address: address)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func goToDetailPage(item: ItemUiModel) {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                guard let content = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                            itemId: item.itemId) else {
                    return
                }
                router.present(for: .itemDetail(content, automaticDisplay: true, showSecurityIssues: true))
            } catch {
                handle(error: error)
            }
        }
    }

    func toggleMonitoring() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                switch infos {
                case let .alias(aliasInfos):
                    try await toggleMonitoringForAlias(alias: aliasInfos.alias)
                case let .customEmail(email):
                    _ = try await toggleMonitoringForCustomEmail(email: email)
                case let .protonAddress(address):
                    try await toggleMonitoringForProtonAddress(address: address)
                }
                shouldDismiss = true
            } catch {
                handle(error: error)
            }
        }
    }
}

private extension DetailMonitoredItemViewModel {
    func setUp() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                switch infos {
                case let .alias(aliasInfos):
                    try await fetchAliasInfos(alias: aliasInfos.alias)
                case let .customEmail(email):
                    try await fetchCustomEmailInfos(email: email)
                case let .protonAddress(address):
                    try await fetchAddressInfos(address: address)
                }
                if let email = infos.email {
                    linkedItems = try await getItemLinkedToBreach(email: email)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func fetchCustomEmailInfos(email: CustomEmail) async throws {
        let breachesInfos = try await passMonitorRepository.getAllBreachesForEmail(email: email)
        updateInfos(email: email.email, breachesInfos: breachesInfos)
    }

    func fetchAddressInfos(address: ProtonAddress) async throws {
        let breachesInfos = try await passMonitorRepository.getAllBreachesForProtonAddress(address: address)
        updateInfos(email: address.email, breachesInfos: breachesInfos)
    }

    func fetchAliasInfos(alias: ItemContent) async throws {
        let breachesInfos = try await passMonitorRepository.getBreachesForAlias(sharedId: alias.shareId,
                                                                                itemId: alias.itemId)
        updateInfos(email: alias.item.aliasEmail ?? "", breachesInfos: breachesInfos)
    }

    func updateInfos(email: String, breachesInfos: EmailBreaches) {
        self.email = email
        numberOfBreaches = breachesInfos.count
        unresolvedBreaches = breachesInfos.breaches.allUnresolvedResolved
        resolvedBreaches = breachesInfos.breaches.allResolvedBreaches
    }

    func handle(error: Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

extension [Breach] {
    var allResolvedBreaches: [Breach] {
        filter(\.isResolved)
    }

    var allUnresolvedResolved: [Breach] {
        filter { !$0.isResolved }
    }
}

private extension BreachDetailsInfo {
    var email: String? {
        switch self {
        case let .alias(aliasInfos):
            aliasInfos.alias.item.aliasEmail
        case let .customEmail(email):
            email.email
        case let .protonAddress(address):
            address.email
        }
    }
}
