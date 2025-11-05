//
// ABTestingManager.swift
// Proton Pass - Created on 04/02/2025.
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

// periphery:ignore:all
import CryptoKit
import Foundation

/// A protocol that experiments can conform to.
/// Conformance to `CaseIterable` allows us to cycle through all possible variants.
public protocol ABTestVariant: CaseIterable {}

public protocol ABTestingManagerProtocol: Sendable {
    func variant<T: ABTestVariant>(for experiment: String,
                                   type: T.Type,
                                   default: T?) -> T?
}

public extension ABTestingManagerProtocol {
    func variant<T: ABTestVariant>(for experiment: String, type: T.Type) -> T? {
        variant(for: experiment, type: type, default: nil)
    }
}

/// A generic A/B test manager that deterministically assigns a variant
/// for any given experiment using a hash of the installation id and experiment identifier.
public final class ABTestingManager: ABTestingManagerProtocol {
    /// Key used to store the installation identifier.
    private let installationIdKey = "me.proton.pass.installationId"

    private let storage: UserDefaults

    public init(storage: UserDefaults = .standard) {
        self.storage = storage
    }

    /// Retrieves the persistent installation identifier.
    /// If it doesn't exist, a new UUID is generated, stored, and returned.
    var installationId: String {
        if let id = storage.string(forKey: installationIdKey) {
            return id
        } else {
            let newId = UUID().uuidString
            storage.set(newId, forKey: installationIdKey)
            return newId
        }
    }

    /// Returns a deterministic variant for a given experiment.
    ///
    /// - Parameters:
    ///   - experiment: A unique string identifier for the experiment.
    ///   - type: The enum type conforming to `ABTestVariant` that represents the possible variants.
    ///   - default: The default variant when not enabled. If `null` is passed, the first variant is choosen as
    /// default one.
    /// - Returns: A variant of the specified enum.
    ///
    /// The method works by combining the experiment identifier with the installation ID,
    /// hashing the result with SHA‑256, and using the first byte of the hash to select a variant.
    public func variant<T: ABTestVariant>(for experiment: String,
                                          type: T.Type,
                                          default: T?) -> T? {
        // Combine the experiment identifier with the persistent installation id.
        let combinedString = experiment + installationId
        let data = Data(combinedString.utf8)
        let hash = SHA256.hash(data: data)
        // Convert the hash to Data
        let hashData = Data(hash)
        let cases = Array(T.allCases)

        // Use the first byte of the hash to decide which variant to assign.
        guard let firstByte = hashData.first else {
            // Fallback: return the default variant if the hash is unexpectedly empty.
            return `default` ?? cases[0]
        }

        let variantIndex = Int(firstByte) % T.allCases.count
        return cases[variantIndex]
    }
}
