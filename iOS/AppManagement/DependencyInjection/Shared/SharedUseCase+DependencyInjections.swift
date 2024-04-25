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

    var preferencesManager: PreferencesManagerProtocol {
        SharedToolingContainer.shared.preferencesManager()
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

    var symmetricKeyProvider: any SymmetricKeyProvider {
        SharedDataContainer.shared.symmetricKeyProvider()
    }

    var userSettingsRepository: any UserSettingsRepositoryProtocol {
        SharedRepositoryContainer.shared.userSettingsRepository()
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

    var setCoreLoggerEnvironment: Factory<SetCoreLoggerEnvironmentUseCase> {
        self { SetCoreLoggerEnvironment() }
    }
}

// MARK: AutoFill

extension SharedUseCasesContainer {
    var mapLoginItem: Factory<MapLoginItemUseCase> {
        self { MapLoginItem(symmetricKeyProvider: self.symmetricKeyProvider) }
    }

    var indexAllLoginItems: Factory<IndexAllLoginItemsUseCase> {
        self { IndexAllLoginItems(itemRepository: self.itemRepository,
                                  shareRepository: SharedRepositoryContainer.shared.shareRepository(),
                                  accessRepository: SharedRepositoryContainer.shared.accessRepository(),
                                  credentialManager: self.credentialManager,
                                  mapLoginItem: self.mapLoginItem(),
                                  logManager: self.logManager) }
    }

    var unindexAllLoginItems: Factory<UnindexAllLoginItemsUseCase> {
        self { UnindexAllLoginItems(manager: self.credentialManager) }
    }
}

// MARK: Spotlight

extension SharedUseCasesContainer {
    var indexItemsForSpotlight: Factory<IndexItemsForSpotlightUseCase> {
        self { IndexItemsForSpotlight(userDataProvider: self.userDataProvider,
                                      itemRepository: self.itemRepository,
                                      datasource: SharedRepositoryContainer.shared
                                          .localSpotlightVaultDatasource(),
                                      logManager: self.logManager) }
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
            GetFeatureFlagStatus(repository: SharedRepositoryContainer.shared.featureFlagsRepository())
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
        self { GenerateTotpToken(totpService: SharedServiceContainer.shared.totpService()) }
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
        self { RevokeCurrentSession(networkRepository: SharedRepositoryContainer.shared.networkRepository()) }
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
                           apiManager: SharedToolingContainer.shared.apiManager(),
                           preferencesManager: self.preferencesManager,
                           databaseService: SharedServiceContainer.shared.databaseService(),
                           syncEventLoop: SharedServiceContainer.shared.syncEventLoop(),
                           vaultsManager: SharedServiceContainer.shared.vaultsManager(),
                           vaultSyncEventStream: SharedDataStreamContainer.shared.vaultSyncEventStream(),
                           credentialManager: SharedServiceContainer.shared.credentialManager(),
                           userDataProvider: self.userDataProvider,
                           featureFlagsRepository: SharedRepositoryContainer.shared.featureFlagsRepository(),
                           passMonitorRepository: SharedRepositoryContainer.shared.passMonitorRepository()) }
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

    var getActiveLoginItems: Factory<GetActiveLoginItemsUseCase> {
        self { GetActiveLoginItems(symmetricKeyProvider: SharedDataContainer.shared.symmetricKeyProvider(),
                                   repository: self.itemRepository) }
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
        self { ForkSession(networkRepository: SharedRepositoryContainer.shared.networkRepository()) }
    }
}

// MARK: - User

extension SharedUseCasesContainer {
    var refreshUserSettings: Factory<RefreshUserSettingsUseCase> {
        self { RefreshUserSettings(userSettingsProtocol: self.userSettingsRepository)
        }
    }

    var toggleSentinel: Factory<ToggleSentinelUseCase> {
        self { ToggleSentinel(userSettingsProtocol: self.userSettingsRepository,
                              userDataProvider: self.userDataProvider) }
    }

    var getSentinelStatus: Factory<GetSentinelStatusUseCase> {
        self { GetSentinelStatus(userSettingsProtocol: self.userSettingsRepository,
                                 userDataProvider: self.userDataProvider) }
    }

    var getUserPlan: Factory<GetUserPlanUseCase> {
        self { GetUserPlan(repository: SharedRepositoryContainer.shared.accessRepository()) }
    }
}

// MARK: Passkey

extension SharedUseCasesContainer {
    var passkeyManagerProvider: Factory<PasskeyManagerProvider> {
        self { PasskeyManagerProviderImpl() }
    }

    var createPasskey: Factory<CreatePasskeyUseCase> {
        self { CreatePasskey(managerProvider: self.passkeyManagerProvider()) }
    }

    var resolvePasskeyChallenge: Factory<ResolvePasskeyChallengeUseCase> {
        self { ResolvePasskeyChallenge(managerProvider: self.passkeyManagerProvider()) }
    }
}

// MARK: Preferences

extension SharedUseCasesContainer {
    var getAppPreferences: Factory<GetAppPreferencesUseCase> {
        self { GetAppPreferences(manager: self.preferencesManager) }
    }

    var getSharedPreferences: Factory<GetSharedPreferencesUseCase> {
        self { GetSharedPreferences(manager: self.preferencesManager) }
    }

    var getUserPreferences: Factory<GetUserPreferencesUseCase> {
        self { GetUserPreferences(manager: self.preferencesManager) }
    }

    var updateAppPreferences: Factory<UpdateAppPreferencesUseCase> {
        self { UpdateAppPreferences(manager: self.preferencesManager) }
    }

    var updateSharedPreferences: Factory<UpdateSharedPreferencesUseCase> {
        self { UpdateSharedPreferences(manager: self.preferencesManager) }
    }

    var updateUserPreferences: Factory<UpdateUserPreferencesUseCase> {
        self { UpdateUserPreferences(manager: self.preferencesManager) }
    }
}

// MARK: Misc

extension SharedUseCasesContainer {
    var copyToClipboard: Factory<CopyToClipboardUseCase> {
        self { CopyToClipboard(getSharedPreferences: self.getSharedPreferences()) }
    }
}

// MARK: - Dark web monitor

extension SharedUseCasesContainer {
    var getCustomEmailSuggestion: Factory<GetCustomEmailSuggestionUseCase> {
        self { GetCustomEmailSuggestion(itemRepository: self.itemRepository,
                                        symmetricKeyProvider: self.symmetricKeyProvider,
                                        validateEmailUseCase: self.validateEmail()) }
    }

    var validateEmail: Factory<ValidateEmailUseCase> {
        self { ValidateEmail() }
    }

    var getAllAliases: Factory<GetAllAliasesUseCase> {
        self { GetAllAliases(itemRepository: self.itemRepository) }
    }
}
