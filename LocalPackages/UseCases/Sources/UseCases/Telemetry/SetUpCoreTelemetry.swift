//
// SetUpCoreTelemetry.swift
// Proton Pass - Created on 09/05/2024.
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
import Core
import Foundation
@preconcurrency import ProtonCoreServices
@preconcurrency import ProtonCoreTelemetry

public protocol SetUpCoreTelemetryUseCase: Sendable {
    func execute()
}

public extension SetUpCoreTelemetryUseCase {
    func callAsFunction() {
        execute()
    }
}

public final class SetUpCoreTelemetry: SetUpCoreTelemetryUseCase {
    private let telemetryService: any TelemetryServiceProtocol
    private let apiServicing: any APIManagerProtocol
    private let userSettingsRepository: any UserSettingsRepositoryProtocol
    private let userManager: any UserManagerProtocol
    private let logger: Logger

    public init(telemetryService: any TelemetryServiceProtocol = TelemetryService.shared,
                apiServicing: any APIManagerProtocol,
                logManager: any LogManagerProtocol,
                userSettingsRepository: any UserSettingsRepositoryProtocol,
                userManager: any UserManagerProtocol) {
        self.telemetryService = telemetryService
        self.apiServicing = apiServicing
        self.userSettingsRepository = userSettingsRepository
        self.userManager = userManager
        logger = .init(manager: logManager)
    }

    public func execute() {
        Task { [weak self] in
            guard let self else { return }
            var telemetry = true
            do {
                let userId = try await userManager.getActiveUserId()
                let apiService = try apiServicing.getApiService(userId: userId)
                telemetryService.setApiService(apiService: apiService)

                telemetry = await userSettingsRepository.getSettings(for: userId).telemetry
            } catch {
                logger.error(error)
            }
            telemetryService.setTelemetryEnabled(telemetry)
        }
    }
}
