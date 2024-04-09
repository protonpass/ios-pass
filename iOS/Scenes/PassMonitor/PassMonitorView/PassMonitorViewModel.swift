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
import Core
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
    @Published private(set) var isFreeUser = false
    @Published private(set) var loading = false
    @Published var isSentinelActive = false
    @Published private(set) var updatingSentinel = false
    @Published var showSentinelSheet = false

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
    private let userDataProvider = resolve(\SharedDataContainer.userDataProvider)
    private let userSettingsRepository = resolve(\SharedRepositoryContainer.userSettingsRepository)
    private let userDefaults: UserDefaults = .standard

    private var cancellables = Set<AnyCancellable>()

    init() {
        setUp()
    }

    func showSecurityWeakness(type: SecurityWeakness) {
        router.present(for: .securityDetail(type))
    }

    func refresh() async {
        do {
            try await passMonitorRepository.refreshSecurityChecks()
        } catch {
            router.display(element: .displayErrorBanner(error))
        }
    }

    func sentinelSheetAction() {
        if isFreeUser {
            upsell(entryPoint: .sentinel)
        } else {
            toggleSentinelState()
        }
    }

    func upsell(entryPoint: UpsellEntry) {
        var upsellElements = [UpsellElement]()
        if userDefaults.bool(forKey: Constants.QA.displaySecurityCenter) {
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
    @MainActor
    func checkSentinel() async {
        guard let userId = try? userDataProvider.getUserId() else {
            return
        }
        let settings = await userSettingsRepository.getSettings(for: userId)
//        isSentinelEligible = settings.highSecurity.eligible
        isSentinelActive = settings.highSecurity.value
    }

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
                let userId = try userDataProvider.getUserId()
                try await userSettingsRepository.toggleSentinel(for: userId)
                await checkSentinel()
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
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
                await checkSentinel()
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }

        passMonitorRepository.weaknessStats
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newWeaknessStats in
                guard let self else {
                    return
                }
                weaknessStats = newWeaknessStats
            }.store(in: &cancellables)
    }
}
