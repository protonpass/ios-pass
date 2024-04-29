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
import DesignSystem
import Entities
import Factory
import Foundation
import Macro
import Screens

enum UpsellEntry {
    case generic
    case missing2fa
    case sentinel
    case darkWebMonitorNoBreach
    case darkWebMonitorBreach

    var description: String {
        switch self {
        case .generic, .missing2fa, .sentinel:
            #localized("Unlock advanced security features and detailed logs to safeguard your online presence.")
        case .darkWebMonitorNoBreach:
            #localized("Dark Web Monitoring is available with a paid plan. Upgrade for immediate access.")
        case .darkWebMonitorBreach:
            // swiftlint:disable:next line_length
            #localized("Your personal data was leaked by an online service in a data breach. Upgrade to view full details and get recommended actions.")
        }
    }
}

@MainActor
final class PassMonitorViewModel: ObservableObject, Sendable {
    @Published private(set) var weaknessStats: WeaknessStats?
    @Published private(set) var breaches: UserBreaches?
    @Published private(set) var numberOfBreaches = 0
    @Published private(set) var isFreeUser = false
    @Published var isSentinelActive = false
    @Published private(set) var updatingSentinel = false
    @Published var showSentinelSheet = false

    private let logger = resolve(\SharedToolingContainer.logger)
    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let monitorStateStream = resolve(\DataStreamContainer.monitorStateStream)
    private let toggleSentinel = resolve(\SharedUseCasesContainer.toggleSentinel)
    private let getSentinelStatus = resolve(\SharedUseCasesContainer.getSentinelStatus)
    private let getFeatureFlagStatus = resolve(\SharedUseCasesContainer.getFeatureFlagStatus)
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let refreshAccessAndMonitorState = resolve(\UseCasesContainer.refreshAccessAndMonitorState)
    private let addTelemetryEvent = resolve(\SharedUseCasesContainer.addTelemetryEvent)

    private var cancellables = Set<AnyCancellable>()

    init() {
        setUp()
    }

    func refresh() async throws {
        try await refreshAccessAndMonitorState()
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
        var upsellElements = [UpsellElement]()
        if getFeatureFlagStatus(with: FeatureFlagType.passSentinelV1) {
            upsellElements.append(UpsellElement(icon: PassIcon.shield2,
                                                title: #localized("Dark Web Monitoring"),
                                                color: PassColor.interactionNormMajor2))
        }
        upsellElements.append(contentsOf: UpsellElement.baseCurrentUpsells)

        let configuration = UpsellingViewConfiguration(icon: PassIcon.passPlus,
                                                       title: #localized("Stay safer online"),
                                                       description: entryPoint.description,
                                                       upsellElements: upsellElements)
        router.present(for: .upselling(configuration))
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

        accessRepository.didUpdateToNewPlan
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else {
                    return
                }
                refreshUserStatus()
            }.store(in: &cancellables)

        monitorStateStream
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, let breachCount = state.breachCount else { return }
                numberOfBreaches = breachCount
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

private extension SecurityWeakness {
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
