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

@MainActor
final class PassMonitorViewModel: ObservableObject, Sendable {
    @Published private(set) var weaknessStats: WeaknessStats?
    @Published private(set) var isFreeUser = false
    @Published private(set) var loading = false
    @Published private(set) var lastUpdate: String?

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)
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
}

private extension PassMonitorViewModel {
    func setUp() {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
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
