//
// MonitorProtonAddressesViewModel.swift
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

import Combine
import Entities
import Factory
import Foundation
import Macro

@MainActor
final class MonitorProtonAddressesViewModel: ObservableObject {
    @Published private(set) var allAddresses: [ProtonAddress]
    @Published private(set) var access: Access?

    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let refreshAccessAndMonitorState = resolve(\UseCasesContainer.refreshAccessAndMonitorState)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    private var cancellables = Set<AnyCancellable>()

    var monitoredAddresses: [ProtonAddress] {
        allAddresses.filter { !$0.monitoringDisabled }
    }

    var excludedAddresses: [ProtonAddress] {
        allAddresses.filter(\.monitoringDisabled)
    }

    init(addresses: [ProtonAddress]) {
        access = accessRepository.access.value?.access
        allAddresses = addresses
        setUp()
    }
}

extension MonitorProtonAddressesViewModel {
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
                let enabled = !access.monitor.protonAddress
                let userId = try await userManager.getActiveUserId()
                try await accessRepository.updateProtonAddressesMonitor(userId: userId,
                                                                        monitored: enabled)
                try await refreshAccessAndMonitorState(userId: userId)

                if enabled {
                    let message = #localized("Proton addresses monitoring resumed")
                    router.display(element: .successMessage(message))
                } else {
                    let message = #localized("Proton addresses monitoring paused")
                    router.display(element: .infosMessage(message))
                }
            } catch {
                handle(error: error)
            }
        }
    }
}

private extension MonitorProtonAddressesViewModel {
    func setUp() {
        accessRepository.access
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { $0 }
            .sink { [weak self] newValue in
                guard let self else { return }
                access = newValue.access
            }
            .store(in: &cancellables)

        passMonitorRepository.darkWebDataSectionUpdate
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] update in
                guard let self else { return }
                if case let .protonAddresses(userBreaches) = update, allAddresses != userBreaches.addresses {
                    allAddresses = userBreaches.addresses
                }
            }
            .store(in: &cancellables)

        passMonitorRepository.userBreaches
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { $0 }
            .sink { [weak self] userBreaches in
                guard let self else { return }
                allAddresses = userBreaches.addresses
            }
            .store(in: &cancellables)
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
