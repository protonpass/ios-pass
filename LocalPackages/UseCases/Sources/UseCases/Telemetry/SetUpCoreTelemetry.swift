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
import ProtonCoreTelemetry

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
    private let apiService: any APIService
    private let userSettingsRepository: any UserSettingsRepositoryProtocol
    private let userManager: any UserManagerProtocol
    private let logger: Logger

    public init(telemetryService: any TelemetryServiceProtocol = TelemetryService.shared,
                apiService: any APIService,
                logManager: any LogManagerProtocol,
                userSettingsRepository: any UserSettingsRepositoryProtocol,
                userManager: any UserManagerProtocol) {
        self.telemetryService = telemetryService
        self.apiService = apiService
        self.userSettingsRepository = userSettingsRepository
        self.userManager = userManager
        logger = .init(manager: logManager)
    }

    public func execute() {
        Task { [weak self] in
            guard let self else { return }
            telemetryService.setApiService(apiService: apiService)
            var telemetry = true
            do {
                let userId = try await userManager.getActiveUserId()
                telemetry = await userSettingsRepository.getSettings(for: userId).telemetry
            } catch {
                logger.error(error)
            }
            telemetryService.setTelemetryEnabled(telemetry)
        }
    }
}
