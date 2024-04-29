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
import Macro

struct DetailMonitoredItemUiModel: Sendable, Hashable {
    let breachCount: Int
    let email: String
    let unresolvedBreaches: [Breach]
    let resolvedBreaches: [Breach]
    let linkedItems: [ItemUiModel]

    var isFullyResolved: Bool {
        unresolvedBreaches.isEmpty
    }
}

@MainActor
final class DetailMonitoredItemViewModel: ObservableObject, Sendable {
    @Published private(set) var state: FetchableObject<DetailMonitoredItemUiModel> = .fetching
    @Published private(set) var shouldDismiss = false

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let getItemsLinkedToBreach = resolve(\UseCasesContainer.getItemsLinkedToBreach)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let toggleMonitoringForAlias = resolve(\UseCasesContainer.toggleMonitoringForAlias)
    private let toggleMonitoringForCustomEmail = resolve(\UseCasesContainer.toggleMonitoringForCustomEmail)
    private let toggleMonitoringForProtonAddress = resolve(\UseCasesContainer.toggleMonitoringForProtonAddress)
    private let removeEmailFromBreachMonitoring = resolve(\UseCasesContainer.removeEmailFromBreachMonitoring)

    var isMonitored: Bool {
        infos.isMonitored
    }

    var isCustomEmail: Bool {
        if case .customEmail = infos {
            true
        } else {
            false
        }
    }

    private let infos: BreachDetailsInfo

    init(infos: BreachDetailsInfo) {
        self.infos = infos
    }

    func fetchData() async {
        do {
            state = .fetching
            let uiModel = try await refreshUiModel()
            state = .fetched(uiModel)
        } catch {
            logger.error(error)
            state = .error(error)
        }
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
                case let .customEmail(email):
                    _ = try await passMonitorRepository.markCustomEmailAsResolved(email: email)
                case let .protonAddress(address):
                    try await passMonitorRepository.markProtonAddressAsResolved(address: address)
                }
                let uiModel = try await refreshUiModel()
                state = .fetched(uiModel)
                router.display(element: .successMessage(#localized("Breaches resolved")))
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
                if !infos.isMonitored {
                    let message = #localized("Monitoring enabled for %@", infos.email)
                    router.display(element: .successMessage(message))
                } else {
                    let message = #localized("Monitoring disabled for %@", infos.email)
                    router.display(element: .infosMessage(message))
                }
                shouldDismiss = true
            } catch {
                handle(error: error)
            }
        }
    }

    func removeCustomMailFromMonitor() {
        if case let .customEmail(email) = infos {
            Task { [weak self] in
                guard let self else {
                    return
                }
                defer { router.display(element: .globalLoading(shouldShow: false)) }
                do {
                    router.display(element: .globalLoading(shouldShow: true))
                    try await removeEmailFromBreachMonitoring(email: email)
                    shouldDismiss = true
                } catch {
                    handle(error: error)
                }
            }
        }
    }
}

private extension DetailMonitoredItemViewModel {
    func refreshUiModel() async throws -> DetailMonitoredItemUiModel {
        let breaches: EmailBreaches
        switch infos {
        case let .alias(aliasInfos):
            let alias = aliasInfos.alias
            breaches = try await passMonitorRepository.getBreachesForAlias(sharedId: alias.shareId,
                                                                           itemId: alias.itemId)
        case let .customEmail(customEmail):
            breaches = try await passMonitorRepository.getAllBreachesForEmail(email: customEmail)
        case let .protonAddress(address):
            breaches = try await passMonitorRepository.getAllBreachesForProtonAddress(address: address)
        }
        let linkedItems: [ItemUiModel] = switch state {
        case let .fetched(uiModel):
            uiModel.linkedItems
        default:
            try await getItemsLinkedToBreach(email: infos.email)
        }
        return .init(breachCount: breaches.count,
                     email: infos.email,
                     unresolvedBreaches: breaches.breaches.allUnresolvedBreaches,
                     resolvedBreaches: breaches.breaches.allResolvedBreaches,
                     linkedItems: linkedItems)
    }

    func handle(error: Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

private extension [Breach] {
    var allResolvedBreaches: [Breach] {
        filter(\.isResolved)
    }

    var allUnresolvedBreaches: [Breach] {
        filter { !$0.isResolved }
    }
}

private extension BreachDetailsInfo {
    var email: String {
        switch self {
        case let .alias(aliasInfos):
            aliasInfos.alias.item.aliasEmail ?? ""
        case let .customEmail(email):
            email.email
        case let .protonAddress(address):
            address.email
        }
    }
}
