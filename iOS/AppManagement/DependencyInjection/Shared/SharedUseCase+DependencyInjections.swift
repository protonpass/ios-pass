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
import UseCases

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

    var preferences: Preferences {
        SharedToolingContainer.shared.preferences()
    }

    var credentialManager: CredentialManagerProtocol {
        SharedServiceContainer.shared.credentialManager()
    }

    var itemRepository: any ItemRepositoryProtocol {
        SharedRepositoryContainer.shared.itemRepository()
    }

    var userDataProvider: any UserDataProvider {
        SharedDataContainer.shared.userDataProvider()
    }

    var apiManager: APIManager {
        SharedToolingContainer.shared.apiManager()
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
        self { AuthenticateBiometrically(keychainService: SharedToolingContainer.shared.keychain()) }
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

    var setUpSentry: Factory<SetUpSentryUseCase> {
        self { SetUpSentry() }
    }

    var sendErrorToSentry: Factory<SendErrorToSentryUseCase> {
        self { SendErrorToSentry(userDataProvider: self.userDataProvider) }
    }
}

// MARK: AutoFill

extension SharedUseCasesContainer {
    var mapLoginItem: Factory<MapLoginItemUseCase> {
        self { MapLoginItem(symmetricKeyProvider: SharedDataContainer.shared.symmetricKeyProvider()) }
    }

    var indexAllLoginItems: Factory<IndexAllLoginItemsUseCase> {
        self { IndexAllLoginItems(itemRepository: self.itemRepository,
                                  shareRepository: SharedRepositoryContainer.shared.shareRepository(),
                                  accessRepository: SharedRepositoryContainer.shared.accessRepository(),
                                  credentialManager: self.credentialManager,
                                  preferences: self.preferences,
                                  mapLoginItem: self.mapLoginItem(),
                                  logManager: self.logManager) }
    }

    var unindexAllLoginItems: Factory<UnindexAllLoginItemsUseCase> {
        self { UnindexAllLoginItems(manager: self.credentialManager) }
    }
}

// MARK: Vault

extension SharedUseCasesContainer {
    var processVaultSyncEvent: Factory<ProcessVaultSyncEventUseCase> {
        self { ProcessVaultSyncEvent() }
    }

    var getMainVault: Factory<GetMainVaultUseCase> {
        self { GetMainVault(vaultsManager: SharedServiceContainer.shared.vaultsManager()) }
    }
}

// MARK: - Shares

extension SharedUseCasesContainer {
    var getCurrentSelectedShareId: Factory<GetCurrentSelectedShareIdUseCase> {
        self { GetCurrentSelectedShareId(vaultsManager: SharedServiceContainer.shared.vaultsManager(),
                                         getMainVault: self.getMainVault()) }
    }
}

// MARK: - Feature Flags

extension SharedUseCasesContainer {
    // periphery:ignore
    var getFeatureFlagStatus: Factory<GetFeatureFlagStatusUseCase> {
        self {
            GetFeatureFlagStatus(repository: SharedRepositoryContainer.shared.featureFlagsRepository(),
                                 logManager: SharedToolingContainer.shared.logManager())
        }
    }
}

// MARK: TOTP

extension SharedUseCasesContainer {
    var sanitizeTotpUriForEditing: Factory<SanitizeTotpUriForEditingUseCase> {
        self { SanitizeTotpUriForEditing() }
    }

    var sanitizeTotpUriForSaving: Factory<SanitizeTotpUriForSavingUseCase> {
        self { SanitizeTotpUriForSaving() }
    }

    var generateTotpToken: Factory<GenerateTotpTokenUseCase> {
        self { GenerateTotpToken(currentDateProvider: SharedToolingContainer.shared.currentDateProvider()) }
    }
}

// MARK: Password Utils

extension SharedUseCasesContainer {
    var generatePassword: Factory<GeneratePasswordUseCase> {
        self { GeneratePassword() }
    }

    var generateRandomWords: Factory<GenerateRandomWordsUseCase> {
        self { GenerateRandomWords() }
    }

    var generatePassphrase: Factory<GeneratePassphraseUseCase> {
        self { GeneratePassphrase() }
    }

    var getPasswordStrength: Factory<GetPasswordStrengthUseCase> {
        self { GetPasswordStrength() }
    }
}

// MARK: Data

extension SharedUseCasesContainer {
    var revokeCurrentSession: Factory<RevokeCurrentSessionUseCase> {
        self { RevokeCurrentSession(apiService: SharedToolingContainer.shared.apiManager().apiService) }
    }

    var deleteLocalDataBeforeFullSync: Factory<DeleteLocalDataBeforeFullSyncUseCase> {
        self { DeleteLocalDataBeforeFullSync(itemRepository: self.itemRepository,
                                             shareRepository: SharedRepositoryContainer.shared.shareRepository(),
                                             shareKeyRepository: SharedRepositoryContainer.shared
                                                 .shareKeyRepository()) }
    }

    var wipeAllData: Factory<WipeAllDataUseCase> {
        self { WipeAllData(logManager: self.logManager,
                           appData: SharedDataContainer.shared.appData(),
                           mainKeyProvider: SharedToolingContainer.shared.mainKeyProvider(),
                           apiManager: SharedToolingContainer.shared.apiManager(),
                           preferences: self.preferences,
                           databaseService: SharedServiceContainer.shared.databaseService(),
                           syncEventLoop: SharedServiceContainer.shared.syncEventLoop(),
                           vaultsManager: SharedServiceContainer.shared.vaultsManager(),
                           vaultSyncEventStream: SharedDataStreamContainer.shared.vaultSyncEventStream(),
                           credentialManager: SharedServiceContainer.shared.credentialManager(),
                           userDataProvider: self.userDataProvider,
                           featureFlagsRepository: SharedRepositoryContainer.shared.featureFlagsRepository()) }
    }
}

// MARK: - Items

extension SharedUseCasesContainer {
    var pinItem: Factory<PinItemUseCase> {
        self { PinItem(itemRepository: self.itemRepository,
                       logManager: self.logManager) }
    }

    var unpinItem: Factory<UnpinItemUseCase> {
        self { UnpinItem(itemRepository: self.itemRepository,
                         logManager: self.logManager) }
    }

    var canEditItem: Factory<CanEditItemUseCase> {
        self { CanEditItem() }
    }
}

// MARK: - Rust Validators

extension SharedUseCasesContainer {
    var validateAliasPrefix: Factory<ValidateAliasPrefixUseCase> {
        self { ValidateAliasPrefix() }
    }
}

// MARK: - Session

extension SharedUseCasesContainer {
    var forkSession: Factory<ForkSessionUseCase> {
        self { ForkSession(apiService: self.apiManager.apiService) }
    }
}

// MARK: - User

extension SharedUseCasesContainer {
    var refreshUserSettings: Factory<RefreshUserSettingsUseCase> {
        self { RefreshUserSettings(userSettingsProtocol: SharedRepositoryContainer.shared.userSettingsRepository())
        }
    }

    var toggleSentinel: Factory<ToggleSentinelUseCase> {
        self { ToggleSentinel(userSettingsProtocol: SharedRepositoryContainer.shared.userSettingsRepository()) }
    }

    var getUserPlan: Factory<GetUserPlanUseCase> {
        self { GetUserPlan(repository: SharedRepositoryContainer.shared.accessRepository()) }
    }
}
