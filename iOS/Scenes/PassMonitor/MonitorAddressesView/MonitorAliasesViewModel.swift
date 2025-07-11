//
// MonitorAliasesViewModel.swift
// Proton Pass - Created on 25/04/2024.
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

import Combine
import Entities
import FactoryKit
import Foundation
import Macro

@MainActor
final class MonitorAliasesViewModel: ObservableObject {
    @Published private(set) var infos: [AliasMonitorInfo]
    @Published private(set) var access: Access?
    @Published private(set) var dismissedCustomDomainExplanation = false

    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let refreshAccessAndMonitorState = resolve(\UseCasesContainer.refreshAccessAndMonitorState)
    private let getAppPreferences = resolve(\SharedUseCasesContainer.getAppPreferences)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    private var cancellables = Set<AnyCancellable>()

    var breachedAliases: [AliasMonitorInfo] {
        infos.filter { $0.breaches != nil && !$0.alias.item.monitoringDisabled }
    }

    var notBreachedAliases: [AliasMonitorInfo] {
        infos.filter { $0.breaches == nil && !$0.alias.item.monitoringDisabled }
    }

    var notMonitoredAliases: [AliasMonitorInfo] {
        infos.filter(\.alias.item.monitoringDisabled)
    }

    init(infos: [AliasMonitorInfo]) {
        access = accessRepository.access.value?.access
        dismissedCustomDomainExplanation = getAppPreferences().dismissedCustomDomainExplanation
        self.infos = infos
        setUp()
    }
}

extension MonitorAliasesViewModel {
    func dismissCustomDomainExplanation() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await preferencesManager.updateAppPreferences(\.dismissedCustomDomainExplanation,
                                                                  value: true)
            } catch {
                handle(error: error)
            }
        }
    }

    func toggleMonitor() {
        guard let access else {
            assertionFailure("Access should not be null")
            return
        }
        Task { [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let enabled = !access.monitor.aliases
                let userId = try await userManager.getActiveUserId()
                try await accessRepository.updateAliasesMonitor(userId: userId, monitored: enabled)
                try await refreshAccessAndMonitorState(userId: userId)

                if enabled {
                    let message = #localized("Hide-my-email aliases monitoring resumed")
                    router.display(element: .successMessage(message))
                } else {
                    let message = #localized("Hide-my-email aliases monitoring paused")
                    router.display(element: .infosMessage(message))
                }
            } catch {
                handle(error: error)
            }
        }
    }
}

private extension MonitorAliasesViewModel {
    func setUp() {
        preferencesManager
            .appPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.dismissedCustomDomainExplanation)
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self else { return }
                dismissedCustomDomainExplanation = newValue
            }
            .store(in: &cancellables)

        passMonitorRepository.darkWebDataSectionUpdate
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] update in
                guard let self else { return }
                if case let .aliases(infos) = update {
                    self.infos = infos
                }
            }
            .store(in: &cancellables)

        accessRepository.access
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { $0 }
            .sink { [weak self] newValue in
                guard let self else { return }
                access = newValue.access
            }
            .store(in: &cancellables)
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
