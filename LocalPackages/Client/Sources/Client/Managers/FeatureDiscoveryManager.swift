//
// FeatureDiscoveryManager.swift
// Proton Pass - Created on 24/06/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Core
import Foundation

/// Some cases are deprecated but kept for the record
public enum NewFeature: String, Sendable, CaseIterable {
    @available(*, deprecated)
    case customItems

    /// Manually implement `allCases` because the compiler doesn't automatically
    /// generate it when there's deprecated casess
    public static var allCases: [NewFeature] {
        []
    }
}

public protocol FeatureDiscoveryManagerProtocol: Sendable {
    /// Keep track of discoveries that we should show. Update as user dismiss discoveries or switch account.
    var eligibleDiscoveries: CurrentValueSubject<Set<NewFeature>, Never> { get }

    func refreshState(userId: String, disallowedFeatures: Set<NewFeature>) async

    func dismissDiscovery(for feature: NewFeature)

    @_spi(QA)
    func undismissDiscovery(for feature: NewFeature)
}

public final class FeatureDiscoveryManager: FeatureDiscoveryManagerProtocol {
    private let storage: UserDefaults
    private let accessRepository: any AccessRepositoryProtocol
    private let logger: Logger
    private nonisolated(unsafe) var disallowedFeatures = Set<NewFeature>()

    public let eligibleDiscoveries = CurrentValueSubject<Set<NewFeature>, Never>([])

    public init(storage: UserDefaults,
                accessRepository: any AccessRepositoryProtocol,
                logManager: any LogManagerProtocol) {
        self.storage = storage
        self.accessRepository = accessRepository
        logger = .init(manager: logManager)
    }

    public func refreshState(userId: String,
                             disallowedFeatures: Set<NewFeature>) async {
        do {
            logger.trace("Refreshing discoveries state for user \(userId)")
            self.disallowedFeatures = disallowedFeatures
            let userInfo = try await accessRepository.getPassUserInformation(userId: userId)
            if userInfo.canDisplayFeatureDiscovery {
                refreshEligibleDiscoveries()
            } else {
                eligibleDiscoveries.send([])
            }
            logger.info("Refreshed discoveries state for user \(userId)")
        } catch {
            eligibleDiscoveries.send([])
            logger
                .error("Failed to refresh discoveries state for user \(userId) \(error.localizedDebugDescription)")
        }
    }

    public func dismissDiscovery(for feature: NewFeature) {
        logger.trace("Dismissed discovery for \(feature.rawValue)")
        storage.set(true, forKey: feature.rawValue)
        refreshEligibleDiscoveries()
    }

    public func undismissDiscovery(for feature: NewFeature) {
        logger.trace("Undismissed discovery for \(feature.rawValue)")
        storage.set(false, forKey: feature.rawValue)
        refreshEligibleDiscoveries()
    }
}

private extension FeatureDiscoveryManager {
    func refreshEligibleDiscoveries() {
        logger.trace("Refreshed eligible discoveries")
        let features = NewFeature.allCases.filter {
            !storage.bool(forKey: $0.rawValue) && !disallowedFeatures.contains($0)
        }
        eligibleDiscoveries.send(Set(features))
    }
}
