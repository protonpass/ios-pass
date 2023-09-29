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

import ProtonCoreNetworking
import ProtonCoreServices

public class DefaultRemoteDatasource: RemoteFeatureFlagsProtocol {
    public let apiService: APIService

    public init(apiService: APIService) {
        self.apiService = apiService
    }

    public func getFlags() async throws -> [FeatureFlag] {
//        let endpoint = GetFeatureFlagEndpoint()
//        let response = try await apiService.exec(endpoint: endpoint)
//        return response.toggles
        []
    }
}

// private extension APIService {
//    /// Async variant that can take an `Endpoint`
//    func exec<E: Request>(endpoint: Request) async throws -> Result {
//        try await withCheckedThrowingContinuation { continuation in
//            perform(request: endpoint) { task, result in
//                NetworkDebugger.printDebugInfo(endpoint: endpoint, task: task, result: result)
//                continuation.resume(with: result)
//            }
//        }
//    }
// }

public final class FeatureFlagsRepository: FeatureFlagsRepositoryProtocol {
    public let userId: String
    private let localDatasource: LocalFeatureFlagsProtocol
    private let remoteDatasource: RemoteFeatureFlagsProtocol
    private let currentBUFlags: any FeatureFlagTypeProtocol.Type

    public init(userId: String,
                currentBUFlags: any FeatureFlagTypeProtocol.Type,
                remoteDatasource: RemoteFeatureFlagsProtocol,
                localDatasource: LocalFeatureFlagsProtocol = DefaultLocalFeatureFlagsDatasource()) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.currentBUFlags = currentBUFlags
        self.userId = userId
    }
}

public extension FeatureFlagsRepository {
    func getFlags() async throws -> FeatureFlags {
        if let localFlags = try await localDatasource.getFeatureFlags(userId: userId) {
            return localFlags
        }
        return try await refreshFlags()
    }

    func refreshFlags() async throws -> FeatureFlags {
        let allflags = try await remoteDatasource.getFlags()
        let flags = filterPassFlags(from: allflags, currentBUFlags: currentBUFlags)
        try await localDatasource.upsertFlags(flags, userId: userId)
        return flags
    }
}

private extension FeatureFlagsRepository {
    /// The new unleash feature flag endpoint doesn't filter flags on project base meaning we receive all proton
    /// flags we want to
    /// filter only the ones that are linked to pass
    /// The flag only appears if it is activated otherwise it it absent from the response
    func filterPassFlags(from flags: [FeatureFlag],
                         currentBUFlags: any FeatureFlagTypeProtocol.Type) -> FeatureFlags {
        let currentPassFlags = flags.filter { element in
            currentBUFlags.isPresent(rawValue: element.name)
        }
        return FeatureFlags(flags: currentPassFlags)
    }
}

//import Core
//
//// sourcery: AutoMockable
//public protocol FeatureFlagsRepositoryProtocol: AnyObject {
//    var userId: String { get }
//    /// Get from local, refresh if not exist
//    func getFlags() async throws -> FeatureFlags
//
//    @discardableResult
//    func refreshFlags() async throws -> FeatureFlags
//}

//public final class FeatureFlagsRepository: FeatureFlagsRepositoryProtocol {
//    public let userId: String
//    private let localDatasource: LocalFeatureFlagsDatasourceProtocol
//    private let remoteDatasource: RemoteFeatureFlagsDatasourceProtocol
//    private let currentBUFlags: any FeatureFlagTypeProtocol.Type
//    private let logger: Logger
//
//    public init(localDatasource: LocalFeatureFlagsDatasourceProtocol,
//                remoteDatasource: RemoteFeatureFlagsDatasourceProtocol,
//                userId: String,
//                logManager: LogManagerProtocol,
//                currentBUFlags: any FeatureFlagTypeProtocol.Type = FeatureFlagType.self) {
//        self.localDatasource = localDatasource
//        self.remoteDatasource = remoteDatasource
//        self.userId = userId
//        self.currentBUFlags = currentBUFlags
//        logger = Logger(manager: logManager)
//    }
//}
//
//public extension FeatureFlagsRepository {
//    func getFlags() async throws -> FeatureFlags {
//        if let localFlags = try await localDatasource.getFeatureFlags(userId: userId) {
//            return localFlags
//        }
//        return try await refreshFlags()
//    }
//
//    func refreshFlags() async throws -> FeatureFlags {
//        let allflags = try await remoteDatasource.getFlags()
//        let flags = filterPassFlags(from: allflags, currentBUFlags: currentBUFlags)
//        try await localDatasource.upsertFlags(flags, userId: userId)
//
//        return flags
//    }
//}
//
//private extension FeatureFlagsRepository {
//    /// The new unleash feature flag endpoint doesn't filter flags on project base meaning we receive all proton
//    /// flags we want to
//    /// filter only the ones that are linked to pass
//    /// The flag only appears if it is activated otherwise it it absent from the response
//    func filterPassFlags(from flags: [FeatureFlag],
//                         currentBUFlags: any FeatureFlagTypeProtocol.Type) -> FeatureFlags {
//        let currentPassFlags = flags.filter { element in
//            currentBUFlags.isPresent(rawValue: element.name)
//        }
//        return FeatureFlags(flags: currentPassFlags)
//    }
//}
