//
// SharedUseCase+DependencyInjections.swift
// Proton Pass - Created on 11/07/2023.
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

import Client
import Core
import CryptoKit
import Factory
import LocalAuthentication

final class SharedUseCasesContainer: SharedContainer, AutoRegistering {
    static let shared = SharedUseCasesContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .shared
    }
}

// MARK: Computed properties

private extension SharedUseCasesContainer {
    var logManager: LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }

    var symmetricKey: SymmetricKey {
        SharedDataContainer.shared.symmetricKey()
    }

    var preferences: Preferences {
        SharedToolingContainer.shared.preferences()
    }
}

// MARK: Permission

extension SharedUseCasesContainer {
    var checkCameraPermission: Factory<CheckCameraPermissionUseCase> {
        self { CheckCameraPermission() }
    }
}

// MARK: Local authentication

extension SharedUseCasesContainer {
    var checkBiometryType: Factory<CheckBiometryTypeUseCase> {
        self { CheckBiometryType() }
    }

    var authenticateBiometrically: Factory<AuthenticateBiometricallyUseCase> {
        self { AuthenticateBiometrically() }
    }

    var getLocalAuthenticationMethods: Factory<GetLocalAuthenticationMethodsUseCase> {
        self { GetLocalAuthenticationMethods(checkBiometryType: self.checkBiometryType()) }
    }

    var saveAllLogs: Factory<SaveAllLogsUseCase> {
        self { SaveAllLogs(logManager: self.logManager) }
    }
}

// MARK: Telemetry

extension SharedUseCasesContainer {
    var addTelemetryEvent: Factory<AddTelemetryEventUseCase> {
        self { AddTelemetryEvent(repository: SharedRepositoryContainer.shared.telemetryEventRepository(),
                                 logManager: self.logManager) }
    }
}

// MARK: AutoFill

extension SharedUseCasesContainer {
    var mapLoginItem: Factory<MapLoginItemUseCase> {
        self { MapLoginItem(key: self.symmetricKey) }
    }

    var indexAllLoginItems: Factory<IndexAllLoginItemsUseCase> {
        self { IndexAllLoginItems(itemRepository: SharedRepositoryContainer.shared.itemRepository(),
                                  shareRepository: SharedRepositoryContainer.shared.shareRepository(),
                                  passPlanRepository: SharedRepositoryContainer.shared.passPlanRepository(),
                                  credentialManager: SharedServiceContainer.shared.credentialManager(),
                                  preferences: self.preferences,
                                  mapLoginItem: self.mapLoginItem(),
                                  logManager: self.logManager) }
    }
}
