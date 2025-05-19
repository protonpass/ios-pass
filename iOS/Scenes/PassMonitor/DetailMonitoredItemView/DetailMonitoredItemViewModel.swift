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
import FactoryKit
import Foundation
import Macro

struct DetailMonitoredItemUiModel: Sendable, Hashable {
    let email: String
    let unresolvedBreaches: [Breach]
    let resolvedBreaches: [Breach]
    let linkedItems: [ItemUiModel]

    var isFullyResolved: Bool {
        unresolvedBreaches.isEmpty
    }
}

@MainActor
final class DetailMonitoredItemViewModel: ObservableObject {
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
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?

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
        setup()
    }

    deinit {
        currentTask?.cancel()
        currentTask = nil
    }

    func fetchData() async {
        do {
            state = .fetching
            if Task.isCancelled {
                return
            }
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
                router.present(for: .itemDetail(content, automaticDisplay: false, showSecurityIssues: true))
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
                let userId = try await userManager.getActiveUserId()
                router.display(element: .globalLoading(shouldShow: true))
                switch infos {
                case let .alias(aliasInfos):
                    try await toggleMonitoringForAlias(userId: userId, alias: aliasInfos.alias)
                case let .customEmail(email):
                    _ = try await toggleMonitoringForCustomEmail(email: email)
                case let .protonAddress(address):
                    try await toggleMonitoringForProtonAddress(address: address)
                }
                if !infos.isMonitored {
                    let message = #localized("Monitoring resumed for %@", infos.email)
                    router.display(element: .successMessage(message))
                } else {
                    let message = #localized("Monitoring paused for %@", infos.email)
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
    func setup() {
        itemRepository.itemsWereUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else {
                    return
                }
                currentTask?.cancel()
                currentTask = Task { [weak self] in
                    guard let self else {
                        return
                    }
                    if Task.isCancelled {
                        return
                    }
                    await fetchData()
                }
            }
            .store(in: &cancellables)
    }

    func refreshUiModel() async throws -> DetailMonitoredItemUiModel {
        let userId = try await userManager.getActiveUserId()
        let breaches: EmailBreaches
        switch infos {
        case let .alias(aliasInfos):
            let alias = aliasInfos.alias
            breaches = try await passMonitorRepository.getBreachesForAlias(sharedId: alias.shareId,
                                                                           itemId: alias.itemId)
        case let .customEmail(customEmail):
            breaches = try await passMonitorRepository.getAllBreachesForEmail(emailId: customEmail.customEmailID)
        case let .protonAddress(address):
            breaches = try await passMonitorRepository.getAllBreachesForProtonAddress(addressId: address.addressID)
        }
        let linkedItems: [ItemUiModel] = switch state {
        case let .fetched(uiModel):
            uiModel.linkedItems
        default:
            try await getItemsLinkedToBreach(userId: userId, email: infos.email)
        }
        return .init(email: infos.email,
                     unresolvedBreaches: breaches.breaches.allUnresolvedBreaches,
                     resolvedBreaches: breaches.breaches.allResolvedBreaches,
                     linkedItems: linkedItems)
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
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
