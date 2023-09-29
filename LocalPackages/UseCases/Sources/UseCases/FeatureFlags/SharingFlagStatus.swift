//
//
// SharingFlagStatus.swift
// Proton Pass - Created on 21/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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

// import Client
// import Core
//
//// sourcery: AutoMockable
// public protocol SharingFlagStatusUseCase: Sendable {
//    func execute() async -> Bool
// }
//
// public extension SharingFlagStatusUseCase {
//    func callAsFunction() async -> Bool {
//        await execute()
//    }
// }
//
// public final class SharingFlagStatus: @unchecked Sendable, SharingFlagStatusUseCase {
//    private let getFeatureFlagStatus: GetFeatureFlagStatusUseCase
//    private let logger: Logger
//
//    public init(getFeatureFlagStatus: GetFeatureFlagStatusUseCase,
//                logManager: LogManagerProtocol) {
//        self.getFeatureFlagStatus = getFeatureFlagStatus
//        logger = Logger(manager: logManager)
//    }
//
//    public func execute() async -> Bool {
//        do {
//            logger.trace("Checking sharing feature flag")
//            return try await getFeatureFlagStatus(with: FeatureFlagType.passSharingV1)
//        } catch {
//            logger.error(error)
//            return false
//        }
//    }
// }
