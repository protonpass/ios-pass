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
    var logManager: any LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }

    var preferencesManager: any PreferencesManagerProtocol {
        SharedToolingContainer.shared.preferencesManager()
    }

    var credentialManager: any CredentialManagerProtocol {
        SharedServiceContainer.shared.credentialManager()
    }

    var itemRepository: any ItemRepositoryProtocol {
        SharedRepositoryContainer.shared.itemRepository()
    }

    var inviteRepository: any InviteRepositoryProtocol {
        SharedRepositoryContainer.shared.inviteRepository()
    }

    var userManager: any UserManagerProtocol {
        SharedServiceContainer.shared.userManager()
    }

    var symmetricKeyProvider: any SymmetricKeyProvider {
        SharedDataContainer.shared.symmetricKeyProvider()
    }

    var userSettingsRepository: any UserSettingsRepositoryProtocol {
        SharedRepositoryContainer.shared.userSettingsRepository()
    }

    var accessRepository: any AccessRepositoryProtocol {
        SharedRepositoryContainer.shared.accessRepository()
    }

    var appContentManager: any AppContentManagerProtocol {
        SharedServiceContainer.shared.appContentManager()
    }

    var apiManager: any APIManagerProtocol {
        SharedToolingContainer.shared.apiManager()
    }

    var authManager: any AuthManagerProtocol {
        SharedToolingContainer.shared.authManager()
    }

    var syncEventLoop: any SyncEventLoopProtocol {
        SharedServiceContainer.shared.syncEventLoop()
    }

    var keychain: any KeychainProtocol {
        SharedToolingContainer.shared.keychain()
    }

    var passMonitorRepository: any PassMonitorRepositoryProtocol {
        SharedRepositoryContainer.shared.passMonitorRepository()
    }

    var shareRepository: any ShareRepositoryProtocol {
        SharedRepositoryContainer.shared.shareRepository()
    }
}

// MARK: App

extension SharedUseCasesContainer {
    var setUpBeforeLaunching: Factory<any SetUpBeforeLaunchingUseCase> {
        self { SetUpBeforeLaunching(keychain: self.keychain,
                                    databaseService: SharedServiceContainer.shared.databaseService(),
                                    symmetricKeyProvider: self.symmetricKeyProvider,
                                    userManager: self.userManager,
                                    prefererencesManager: self.preferencesManager,
                                    authManager: SharedDataContainer.shared.credentialProvider(),
                                    applyMigration: self.applyAppMigration()) }
    }
}

// MARK: Permission

extension SharedUseCasesContainer {
    var checkCameraPermission: Factory<any CheckCameraPermissionUseCase> {
        self { CheckCameraPermission() }
    }
}

// MARK: Local authentication

extension SharedUseCasesContainer {
    var checkBiometryType: Factory<any CheckBiometryTypeUseCase> {
        self { CheckBiometryType() }
    }

    var authenticateBiometrically: Factory<any AuthenticateBiometricallyUseCase> {
        self { AuthenticateBiometrically(keychainService: self.keychain) }
    }

    var getLocalAuthenticationMethods: Factory<any GetLocalAuthenticationMethodsUseCase> {
        self { GetLocalAuthenticationMethods(checkBiometryType: self.checkBiometryType(),
                                             accessRepository: self.accessRepository,
                                             organizationRepository: SharedRepositoryContainer.shared
                                                 .organizationRepository()) }
    }

    var saveAllLogs: Factory<any SaveAllLogsUseCase> {
        self { SaveAllLogs(logManager: self.logManager) }
    }
}

// MARK: Telemetry

extension SharedUseCasesContainer {
    var addTelemetryEvent: Factory<any AddTelemetryEventUseCase> {
        self { AddTelemetryEvent(repository: SharedRepositoryContainer.shared.telemetryEventRepository(),
                                 userManager: self.userManager,
                                 logManager: self.logManager) }
    }

    var sendTelemetryEvent: Factory<any SendTelemetryEventUseCase> {
        self {
            SendTelemetryEvent(datasource: SharedRepositoryContainer.shared.remoteTelemetryEventDatasource(),
                               logManager: self.logManager)
        }
    }

    var setUpSentry: Factory<any SetUpSentryUseCase> {
        self { SetUpSentry() }
    }

    var sendErrorToSentry: Factory<any SendErrorToSentryUseCase> {
        self { SendErrorToSentry() }
    }

    var sendMessageToSentry: Factory<any SendMessageToSentryUseCase> {
        self { SendMessageToSentry() }
    }

    var setCoreLoggerEnvironment: Factory<any SetCoreLoggerEnvironmentUseCase> {
        self { SetCoreLoggerEnvironment() }
    }

    var setUpCoreTelemetry: Factory<any SetUpCoreTelemetryUseCase> {
        self { SetUpCoreTelemetry(telemetryService: SharedServiceContainer.shared.telemetryService(),
                                  apiServicing: SharedToolingContainer.shared.apiManager(),
                                  logManager: self.logManager,
                                  userSettingsRepository: self.userSettingsRepository,
                                  userManager: self.userManager) }
    }
}

// MARK: AutoFill

extension SharedUseCasesContainer {
    var mapLoginItem: Factory<any MapLoginItemUseCase> {
        self { MapLoginItem() }
    }

    var indexAllLoginItems: Factory<any IndexAllLoginItemsUseCase> {
        self { IndexAllLoginItems(userManager: self.userManager,
                                  itemRepository: self.itemRepository,
                                  shareRepository: self.shareRepository,
                                  localAccessDatasource: SharedRepositoryContainer.shared.localAccessDatasource(),
                                  credentialManager: self.credentialManager,
                                  mapLoginItem: self.mapLoginItem(),
                                  symmetricKeyProvider: self.symmetricKeyProvider,
                                  logManager: self.logManager) }
    }

    var unindexAllLoginItems: Factory<any UnindexAllLoginItemsUseCase> {
        self { UnindexAllLoginItems(manager: self.credentialManager) }
    }
}

// MARK: Spotlight

extension SharedUseCasesContainer {
    var indexItemsForSpotlight: Factory<any IndexItemsForSpotlightUseCase> {
        self { IndexItemsForSpotlight(userManager: self.userManager,
                                      itemRepository: self.itemRepository,
                                      datasource: SharedRepositoryContainer.shared
                                          .localSpotlightVaultDatasource(),
                                      logManager: self.logManager) }
    }
}

// MARK: Vault

extension SharedUseCasesContainer {
    var processVaultSyncEvent: Factory<any ProcessVaultSyncEventUseCase> {
        self { ProcessVaultSyncEvent() }
    }

    var getMainVault: Factory<any GetMainVaultUseCase> {
        self { GetMainVault(appContentManager: self.appContentManager) }
    }

    var fullContentSync: Factory<any FullContentSyncUseCase> {
        self { FullContentSync(syncEventLoop: SharedServiceContainer.shared.syncEventLoop(),
                               appContentManager: self.appContentManager) }
    }
}

// MARK: - Feature Flags

extension SharedUseCasesContainer {
    // periphery:ignore
    var getFeatureFlagStatus: Factory<any GetFeatureFlagStatusUseCase> {
        self {
            GetFeatureFlagStatus(repository: SharedRepositoryContainer.shared.featureFlagsRepository())
        }
    }
}

// MARK: TOTP

extension SharedUseCasesContainer {
    var sanitizeTotpUriForEditing: Factory<any SanitizeTotpUriForEditingUseCase> {
        self { SanitizeTotpUriForEditing() }
    }

    var sanitizeTotpUriForSaving: Factory<any SanitizeTotpUriForSavingUseCase> {
        self { SanitizeTotpUriForSaving() }
    }

    var generateTotpToken: Factory<any GenerateTotpTokenUseCase> {
        self { GenerateTotpToken(totpService: SharedServiceContainer.shared.totpService()) }
    }
}

// MARK: Password Utils

extension SharedUseCasesContainer {
    var generatePassword: Factory<any GeneratePasswordUseCase> {
        self { GeneratePassword() }
    }

    var generateRandomWords: Factory<any GenerateRandomWordsUseCase> {
        self { GenerateRandomWords() }
    }

    var generatePassphrase: Factory<any GeneratePassphraseUseCase> {
        self { GeneratePassphrase() }
    }

    var getPasswordStrength: Factory<any GetPasswordStrengthUseCase> {
        self { GetPasswordStrength() }
    }
}

// MARK: Data

extension SharedUseCasesContainer {
    var revokeCurrentSession: Factory<any RevokeCurrentSessionUseCase> {
        self { RevokeCurrentSession(networkRepository: SharedRepositoryContainer.shared.networkRepository(),
                                    userManager: self.userManager) }
    }

    var deleteLocalDataBeforeFullSync: Factory<any DeleteLocalDataBeforeFullSyncUseCase> {
        self { DeleteLocalDataBeforeFullSync(itemRepository: self.itemRepository,
                                             shareRepository: self.shareRepository,
                                             shareKeyRepository: SharedRepositoryContainer.shared
                                                 .shareKeyRepository()) }
    }

    var logOutUser: Factory<any LogOutUserUseCase> {
        self {
            LogOutUser(userManager: self.userManager,
                       syncEventLoop: SharedServiceContainer.shared.syncEventLoop(),
                       preferencesManager: self.preferencesManager,
                       removeUserLocalData: self.removeUserLocalData(),
                       featureFlagsRepository: SharedRepositoryContainer.shared.featureFlagsRepository(),
                       passMonitorRepository: self.passMonitorRepository,
                       accessRepository: self.accessRepository,
                       appContentManager: self.appContentManager,
                       apiManager: self.apiManager,
                       authManager: self.authManager,
                       credentialManager: SharedServiceContainer.shared.credentialManager(),
                       switchUser: self.switchUser())
        }
    }

    var getUserUiModels: Factory<any GetUserUiModelsUseCase> {
        self { GetUserUiModels(userManager: self.userManager,
                               localAccessDatasource: SharedRepositoryContainer.shared.localAccessDatasource()) }
    }
}

// MARK: - Items

extension SharedUseCasesContainer {
    var pinItems: Factory<any PinItemsUseCase> {
        self { PinItems(itemRepository: self.itemRepository) }
    }

    var unpinItems: Factory<any UnpinItemsUseCase> {
        self { UnpinItems(itemRepository: self.itemRepository) }
    }

    var canEditItem: Factory<any CanEditItemUseCase> {
        self { CanEditItem() }
    }

    var getActiveLoginItems: Factory<any GetActiveLoginItemsUseCase> {
        self { GetActiveLoginItems(symmetricKeyProvider: SharedDataContainer.shared.symmetricKeyProvider(),
                                   repository: self.itemRepository) }
    }

    var createVaultAndImportLogins: Factory<any CreateVaultAndImportLoginsUseCase> {
        self { CreateVaultAndImportLogins(shareRepository: self.shareRepository,
                                          itemRepository: self.itemRepository) }
    }
}

// MARK: - Rust Validators

extension SharedUseCasesContainer {
    var validateAliasPrefix: Factory<any ValidateAliasPrefixUseCase> {
        self { ValidateAliasPrefix() }
    }

    var getRootDomain: Factory<any GetRootDomainUseCase> {
        // Register as `cached` because the list of root domain is long
        self { GetRootDomain() }
            .cached
    }

    var matchUrls: Factory<any MatchUrlsUseCase> {
        self { MatchUrls(getRootDomain: self.getRootDomain()) }
    }
}

// MARK: - Session

extension SharedUseCasesContainer {
//    var forkSession: Factory<any ForkSessionUseCase> {
//        self { ForkSession(networkRepository: SharedRepositoryContainer.shared.networkRepository(),
//                           userManager: self.userManager) }
//    }
}

// MARK: - User

extension SharedUseCasesContainer {
    var refreshUserSettings: Factory<any RefreshUserSettingsUseCase> {
        self { RefreshUserSettings(userSettingsProtocol: self.userSettingsRepository)
        }
    }

    var toggleSentinel: Factory<any ToggleSentinelUseCase> {
        self { ToggleSentinel(userSettingsProtocol: self.userSettingsRepository,
                              userManager: self.userManager) }
    }

    var getSentinelStatus: Factory<any GetSentinelStatusUseCase> {
        self { GetSentinelStatus(userSettingsProtocol: self.userSettingsRepository,
                                 userManager: self.userManager) }
    }

    var removeUserLocalData: Factory<any RemoveUserLocalDataUseCase> {
        self {
            let container = SharedRepositoryContainer.shared
            return RemoveUserLocalData(accessDatasource: container.localAccessDatasource(),
                                       authCredentialDatasource: container.localAuthCredentialDatasource(),
                                       itemDatasource: container.localItemDatasource(),
                                       itemReadEventDatasource: container.localItemReadEventDatasource(),
                                       organizationDatasource: container.localOrganizationDatasource(),
                                       searchEntryDatasource: container.localSearchEntryDatasource(),
                                       shareDatasource: container.localShareDatasource(),
                                       shareEventIdDatasource: container.localShareEventIDDatasource(),
                                       shareKeyDatasource: container.localShareKeyDatasource(),
                                       spotlightVaultDatasource: container.localSpotlightVaultDatasource(),
                                       telemetryEventDatasource: container.localTelemetryEventDatasource(),
                                       userDataDatasource: container.localUserDataDatasource(),
                                       userPreferencesDatasource: container.userPreferencesDatasource(),
                                       inAppNotificationDatasource: container.localInAppNotificationDatasource())
        }
    }

    var switchUser: Factory<any SwitchUserUseCase> {
        self { SwitchUser(userManager: self.userManager,
                          appContentManager: self.appContentManager,
                          preferencesManager: self.preferencesManager,
                          apiManager: self.apiManager,
                          syncEventLoop: self.syncEventLoop,
                          refreshFeatureFlags: self.refreshFeatureFlags(),
                          inviteRepository: self.inviteRepository) }
    }

    var addAndSwitchToNewUserAccount: Factory<any AddAndSwitchToNewUserAccountUseCase> {
        self { AddAndSwitchToNewUserAccount(syncEventLoop: self.syncEventLoop,
                                            userManager: self.userManager,
                                            authManager: self.authManager,
                                            preferencesManager: self.preferencesManager,
                                            apiManager: self.apiManager,
                                            fullContentSync: self.fullContentSync(),
                                            refreshFeatureFlags: self.refreshFeatureFlags(),
                                            inviteRepository: self.inviteRepository) }
    }

    var logOutAllAccounts: Factory<any LogOutAllAccountsUseCase> {
        self { LogOutAllAccounts(userManager: self.userManager,
                                 syncEventLoop: self.syncEventLoop,
                                 preferencesManager: self.preferencesManager,
                                 removeUserLocalData: self.removeUserLocalData(),
                                 featureFlagsRepository: SharedRepositoryContainer.shared.featureFlagsRepository(),
                                 passMonitorRepository: self.passMonitorRepository,
                                 appContentManager: self.appContentManager,
                                 apiManager: self.apiManager,
                                 authManager: self.authManager,
                                 credentialManager: SharedServiceContainer.shared.credentialManager(),
                                 keychain: self.keychain) }
    }
}

// MARK: Passkey

extension SharedUseCasesContainer {
    var passkeyManagerProvider: Factory<any PasskeyManagerProvider> {
        self { PasskeyManagerProviderImpl() }
    }

    var createPasskey: Factory<any CreatePasskeyUseCase> {
        self { CreatePasskey(managerProvider: self.passkeyManagerProvider()) }
    }

    var resolvePasskeyChallenge: Factory<any ResolvePasskeyChallengeUseCase> {
        self { ResolvePasskeyChallenge(managerProvider: self.passkeyManagerProvider()) }
    }
}

// MARK: Preferences

extension SharedUseCasesContainer {
    var getAppPreferences: Factory<any GetAppPreferencesUseCase> {
        self { GetAppPreferences(manager: self.preferencesManager) }
    }

    var getSharedPreferences: Factory<any GetSharedPreferencesUseCase> {
        self { GetSharedPreferences(manager: self.preferencesManager) }
    }

    var getUserPreferences: Factory<any GetUserPreferencesUseCase> {
        self { GetUserPreferences(manager: self.preferencesManager) }
    }

    var updateAppPreferences: Factory<any UpdateAppPreferencesUseCase> {
        self { UpdateAppPreferences(manager: self.preferencesManager) }
    }

    var updateSharedPreferences: Factory<any UpdateSharedPreferencesUseCase> {
        self { UpdateSharedPreferences(manager: self.preferencesManager) }
    }

    var updateUserPreferences: Factory<any UpdateUserPreferencesUseCase> {
        self { UpdateUserPreferences(manager: self.preferencesManager) }
    }
}

// MARK: Misc

extension SharedUseCasesContainer {
    var copyToClipboard: Factory<any CopyToClipboardUseCase> {
        self { CopyToClipboard(getSharedPreferences: self.getSharedPreferences()) }
    }

    var applyAppMigration: Factory<any ApplyAppMigrationUseCase> {
        self { ApplyAppMigration(dataMigrationManager: SharedServiceContainer.shared.dataMigrationManager(),
                                 userManager: self.userManager,
                                 appData: SharedDataContainer.shared.appData(),
                                 authManager: self.authManager,
                                 itemDatasource: SharedRepositoryContainer.shared.localItemDatasource(),
                                 searchEntryDatasource: SharedRepositoryContainer.shared
                                     .localSearchEntryDatasource(),
                                 shareKeyDatasource: SharedRepositoryContainer.shared.localShareKeyDatasource(),
                                 logManager: self.logManager) }
    }
}

// MARK: - Dark web monitor

extension SharedUseCasesContainer {
    var getCustomEmailSuggestion: Factory<any GetCustomEmailSuggestionUseCase> {
        self { GetCustomEmailSuggestion(itemRepository: self.itemRepository,
                                        symmetricKeyProvider: self.symmetricKeyProvider,
                                        validateEmailUseCase: self.validateEmail()) }
    }

    var validateEmail: Factory<any ValidateEmailUseCase> {
        self { ValidateEmail() }
    }

    var getAllAliases: Factory<any GetAllAliasesUseCase> {
        self { GetAllAliases(itemRepository: self.itemRepository) }
    }

    var sendUserMonitoringStats: Factory<any SendUserMonitoringStatsUseCase> {
        self {
            SendUserMonitoringStats(passMonitorRepository: self.passMonitorRepository,
                                    accessRepository: self.accessRepository,
                                    userManager: self.userManager,
                                    storage: kSharedUserDefaults)
        }
    }
}

// MARK: - Flags

extension SharedUseCasesContainer {
    var refreshFeatureFlags: Factory<any RefreshFeatureFlagsUseCase> {
        self { RefreshFeatureFlags(repository: SharedRepositoryContainer.shared.featureFlagsRepository(),
                                   apiServicing: self.apiManager,
                                   userManager: self.userManager,
                                   logManager: self.logManager) }
    }
}

// MARK: - File attachments

extension SharedUseCasesContainer {
    var generateDatedFileName: Factory<any GenerateDatedFileNameUseCase> {
        self { GenerateDatedFileName() }
    }

    var writeToUrl: Factory<any WriteToUrlUseCase> {
        self { WriteToUrl() }
    }

    var getFileSize: Factory<any GetFileSizeUseCase> {
        self { GetFileSize() }
    }

    var getMimeType: Factory<any GetMimeTypeUseCase> {
        self { GetMimeType() }
    }

    var getFileGroup: Factory<any GetFileGroupUseCase> {
        self { GetFileGroup() }
    }

    var formatFileAttachmentSize: Factory<any FormatFileAttachmentSizeUseCase> {
        self { FormatFileAttachmentSize() }
    }

    var generateFileTempUrl: Factory<any GenerateFileTempUrlUseCase> {
        self { GenerateFileTempUrl() }
    }

    var downloadAndDecryptFile: Factory<any DownloadAndDecryptFileUseCase> {
        self { DownloadAndDecryptFile(generateFileTempUrl: self.generateFileTempUrl(),
                                      shareRepository: self.shareRepository,
                                      keyManager: SharedRepositoryContainer.shared.passKeyManager(),
                                      apiService: SharedToolingContainer.shared.apiServiceLite()) }
    }

    var getFilesToLink: Factory<any GetFilesToLinkUseCase> {
        self { GetFilesToLink() }
    }

    var clearCacheForLoggedOutUsers: Factory<any ClearCacheForLoggedOutUsersUseCase> {
        self {
            ClearCacheForLoggedOutUsers(datasource: SharedRepositoryContainer.shared.localUserDataDatasource())
        }
    }
}
