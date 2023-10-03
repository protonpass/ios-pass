//
// FeatureFlagsRepository.swift
// Proton - Created on 29/09/2023.
// Copyright (c) 2023 Proton Technologies AG
//
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

public struct FeatureFlagsConfiguration {
    public let userId: String
    public let currentBUFlags: any FeatureFlagTypeProtocol.Type

    public init(userId: String,
                currentBUFlags: any FeatureFlagTypeProtocol.Type) {
        self.userId = userId
        self.currentBUFlags = currentBUFlags
    }
}

public actor FeatureFlagsRepository: FeatureFlagsRepositoryProtocol {
    private let localDatasource: LocalFeatureFlagsProtocol
    private let remoteDatasource: RemoteFeatureFlagsProtocol
    private var configuration: FeatureFlagsConfiguration

    public init(configuration: FeatureFlagsConfiguration,
                localDatasource: LocalFeatureFlagsProtocol,
                remoteDatasource: RemoteFeatureFlagsProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.configuration = configuration
    }
}

public extension FeatureFlagsRepository {
    func getFlags() async throws -> FeatureFlags {
        if let localFlags = try await localDatasource.getFeatureFlags(userId: configuration.userId) {
            return localFlags
        }
        return try await refreshFlags()
    }

    func getFlag(for key: any FeatureFlagTypeProtocol) async -> FeatureFlag? {
        guard let flags = try? await getFlags().flags else {
            return nil
        }
        return flags.first { $0.name == key.rawValue }
    }

    func refreshFlags() async throws -> FeatureFlags {
        let allflags = try await remoteDatasource.getFlags()
        let flags = filterFlags(from: allflags, currentBUFlags: configuration.currentBUFlags)
        try await localDatasource.upsertFlags(flags, userId: configuration.userId)
        return flags
    }

    func isFlagEnable(for key: any FeatureFlagTypeProtocol) async -> Bool {
        do {
            let flags = try await getFlags().flags
            return flags.first { $0.name == key.rawValue }?.enabled ?? false
        } catch {
            return false
        }
    }

    func update(with configuration: FeatureFlagsConfiguration) {
        self.configuration = configuration
    }

    func resetFlags() async {
        await localDatasource.cleanAllFlags()
    }

    func resetFlags(for userId: String) async {
        await localDatasource.cleanFlags(for: userId)
    }
}

private extension FeatureFlagsRepository {
    /// The new unleash feature flag endpoint doesn't filter flags on project base meaning we receive all proton
    /// flags we want to
    /// filter only the ones that are linked to pass
    /// The flag only appears if it is activated otherwise it it absent from the response
    func filterFlags(from flags: [FeatureFlag],
                     currentBUFlags: any FeatureFlagTypeProtocol.Type) -> FeatureFlags {
        let currentFlags = flags.filter { element in
            currentBUFlags.isPresent(rawValue: element.name)
        }
        return FeatureFlags(flags: currentFlags)
    }
}
