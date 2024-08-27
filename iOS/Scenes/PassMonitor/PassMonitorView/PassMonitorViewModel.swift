//
//
// PassMonitorViewModel.swift
// Proton Pass - Created on 29/02/2024.
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
import Macro

@MainActor
final class PassMonitorViewModel: ObservableObject, Sendable {
    @Published private(set) var weaknessStats: WeaknessStats?
    @Published private(set) var breaches: UserBreaches?
    @Published private(set) var numberOfBreaches = 0
    @Published private(set) var isFreeUser = false
    @Published var isSentinelActive = false
    @Published private(set) var updatingSentinel = false
    @Published var showSentinelSheet = false
    @Published private(set) var latestBreachInfo: LatestBreachDomainInfo?

    private let logger = resolve(\SharedToolingContainer.logger)
    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let monitorStateStream = resolve(\DataStreamContainer.monitorStateStream)
    private let toggleSentinel = resolve(\SharedUseCasesContainer.toggleSentinel)
    private let getSentinelStatus = resolve(\SharedUseCasesContainer.getSentinelStatus)
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let refreshAccessAndMonitorState = resolve(\UseCasesContainer.refreshAccessAndMonitorState)
    let addTelemetryEvent = resolve(\SharedUseCasesContainer.addTelemetryEvent)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    private var refreshingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var isBreached: Bool {
        !monitorStateStream.value.noBreaches
    }

    init() {
        setUp()
    }

    func refresh() async throws {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        try await refreshAccessAndMonitorState(userId: userId)
        addTelemetryEvent(with: .monitorDisplayHome)
    }

    func showSecurityWeakness(type: SecurityWeakness) {
        router.present(for: .securityDetail(type))
        addTelemetryEvent(with: type.telemetryEventType)
    }

    func sentinelSheetAction() {
        if isFreeUser {
            upsell(entryPoint: .sentinel)
        } else {
            showSentinelSheet = false
            toggleSentinelState()
        }
    }

    func upsell(entryPoint: UpsellEntry) {
        router.present(for: .upselling(entryPoint.defaultConfiguration))
    }
}

// MARK: - Sentinel

extension PassMonitorViewModel {
    func toggleSentinelState() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                updatingSentinel = false
            }
            do {
                updatingSentinel = true
                isSentinelActive = try await toggleSentinel()
            } catch PassError.sentinelNotEligible {
                router.present(for: .upselling(.essentials))
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func showSentinelInformation() {
        router.navigate(to: .urlPage(urlString: "https://proton.me/support/proton-sentinel"))
    }
}

private extension PassMonitorViewModel {
    func setUp() {
        refreshUserStatus()

        passMonitorRepository.weaknessStats
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else {
                    return
                }
                weaknessStats = newValue
            }.store(in: &cancellables)

        passMonitorRepository.userBreaches
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                breaches = newValue
            }
            .store(in: &cancellables)

        Publishers.Merge(userManager.currentActiveUser.map { _ in () },
                         accessRepository.didUpdateToNewPlan.map { _ in () })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                refreshUserStatus()
            }.store(in: &cancellables)

        monitorStateStream
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                numberOfBreaches = state.breachCount ?? 0
                latestBreachInfo = state.latestBreachDomainInfo
            }.store(in: &cancellables)

        passMonitorRepository.darkWebDataSectionUpdate
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                refreshingTask?.cancel()
                refreshingTask = Task { [weak self] in
                    guard let self else {
                        return
                    }
                    if Task.isCancelled {
                        return
                    }
                    try? await refresh()
                }
            }.store(in: &cancellables)
    }

    func refreshUserStatus() {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
                isSentinelActive = await getSentinelStatus()
            } catch {
                handle(error: error)
            }
        }
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

extension SecurityWeakness {
    var telemetryEventType: TelemetryEventType {
        switch self {
        case .weakPasswords:
            .monitorDisplayWeakPasswords
        case .reusedPasswords:
            .monitorDisplayReusedPasswords
        case .breaches:
            .monitorDisplayDarkWebMonitoring
        case .missing2FA:
            .monitorDisplayMissing2FA
        case .excludedItems:
            .monitorDisplayExcludedItems
        }
    }
}
