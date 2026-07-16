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

// import Client
// import Core
// import CryptoKit
// import DIComposition
// import FactoryKit
// import LocalAuthentication
// import Stores
// import UseCases
//
// final class SharedUseCasesContainer: SharedContainer, AutoRegistering {
//    static let shared = SharedUseCasesContainer()
//    let manager = ContainerManager()
//
//    func autoRegister() {
//        manager.defaultScope = .shared
//    }
// }
//
//// MARK: Computed properties
//
// private extension SharedUseCasesContainer {
//    var logManager: any LogManagerProtocol {
//        ToolingContainer.shared.logManager()
//    }
//
//    var preferencesManager: any PreferencesManagerProtocol {
//        ToolingContainer.shared.preferencesManager()
//    }
//
//    var credentialManager: any CredentialManagerProtocol {
//        ServiceContainer.shared.credentialManager()
//    }
//
//    var itemRepository: any ItemRepositoryProtocol {
//        RepositoryContainer.shared.itemRepository()
//    }
//
//    var inviteRepository: any InviteRepositoryProtocol {
//        RepositoryContainer.shared.inviteRepository()
//    }
//
//    var userManager: any UserManagerProtocol {
//        ServiceContainer.shared.userManager()
//    }
//
//    var symmetricKeyProvider: any SymmetricKeyProvider {
//        DataContainer.shared.symmetricKeyProvider()
//    }
//
//    var userSettingsRepository: any UserSettingsRepositoryProtocol {
//        RepositoryContainer.shared.userSettingsRepository()
//    }
//
//    var accessRepository: any AccessRepositoryProtocol {
//        RepositoryContainer.shared.accessRepository()
//    }
//
//    @MainActor
//    var appContentManager: any AppContentManagerProtocol {
//        ServiceContainer.shared.appContentManager()
//    }
//
//    var apiManager: any APIManagerProtocol {
//        ToolingContainer.shared.apiManager()
//    }
//
//    var authManager: any AuthManagerProtocol {
//        ToolingContainer.shared.authManager()
//    }
//
//    var syncEventLoop: any SyncEventLoopProtocol {
//        ServiceContainer.shared.syncEventLoop()
//    }
//
//    var keychain: any KeychainProtocol {
//        ToolingContainer.shared.keychain()
//    }
//
//    var passMonitorRepository: any PassMonitorRepositoryProtocol {
//        RepositoryContainer.shared.passMonitorRepository()
//    }
//
//    var shareRepository: any ShareRepositoryProtocol {
//        RepositoryContainer.shared.shareRepository()
//    }
//
//    var organizationRepository: any OrganizationRepositoryProtocol {
//        RepositoryContainer.shared.organizationRepository()
//    }
// }
//
//// MARK: App
//
// extension SharedUseCasesContainer {
//    var setUpBeforeLaunching: Factory<any SetUpBeforeLaunchingUseCase> {
//        self { SetUpBeforeLaunching(keychain: self.keychain,
//                                    databaseService: ServiceContainer.shared.databaseService(),
//                                    symmetricKeyProvider: self.symmetricKeyProvider,
//                                    userManager: self.userManager,
//                                    prefererencesManager: self.preferencesManager,
//                                    authManager: DataContainer.shared.credentialProvider(),
//                                    applyMigration: self.applyAppMigration()) }
//    }
// }
//
//// MARK: Permission
//
// extension SharedUseCasesContainer {
//    var checkCameraPermission: Factory<any CheckCameraPermissionUseCase> {
//        self { CheckCameraPermission() }
//    }
// }
//
//// MARK: Local authentication
//
// extension SharedUseCasesContainer {
//    var checkBiometryType: Factory<any CheckBiometryTypeUseCase> {
//        self { CheckBiometryType() }
//    }
//
//    var authenticateBiometrically: Factory<any AuthenticateBiometricallyUseCase> {
//        self { AuthenticateBiometrically(keychainService: self.keychain) }
//    }
//
//    var getLocalAuthenticationMethods: Factory<any GetLocalAuthenticationMethodsUseCase> {
//        self { GetLocalAuthenticationMethods(checkBiometryType: self.checkBiometryType(),
//                                             accessRepository: self.accessRepository,
//                                             organizationRepository: self.organizationRepository) }
//    }
//
//    var saveAllLogs: Factory<any SaveAllLogsUseCase> {
//        self { SaveAllLogs(logManager: self.logManager) }
//    }
// }
//
//// MARK: Telemetry
//
// extension SharedUseCasesContainer {
//    var addTelemetryEvent: Factory<any AddTelemetryEventUseCase> {
//        self { AddTelemetryEvent(repository: RepositoryContainer.shared.telemetryEventRepository(),
//                                 userManager: self.userManager,
//                                 logManager: self.logManager) }
//    }
//
//    // periphery:ignore
//    var sendTelemetryEvent: Factory<any SendTelemetryEventUseCase> {
//        self {
//            SendTelemetryEvent(datasource: RepositoryContainer.shared.remoteTelemetryEventDatasource(),
//                               logManager: self.logManager)
//        }
//    }
//
//    var setUpSentry: Factory<any SetUpSentryUseCase> {
//        self { SetUpSentry() }
//    }
//
//    var sendErrorToSentry: Factory<any SendErrorToSentryUseCase> {
//        self { SendErrorToSentry() }
//    }
//
//    var sendMessageToSentry: Factory<any SendMessageToSentryUseCase> {
//        self { SendMessageToSentry() }
//    }
//
//    var setCoreLoggerEnvironment: Factory<any SetCoreLoggerEnvironmentUseCase> {
//        self { SetCoreLoggerEnvironment() }
//    }
//
//    var setUpCoreTelemetry: Factory<any SetUpCoreTelemetryUseCase> {
//        self { SetUpCoreTelemetry(telemetryService: ServiceContainer.shared.telemetryService(),
//                                  apiServicing: ToolingContainer.shared.apiManager(),
//                                  logManager: self.logManager,
//                                  userSettingsRepository: self.userSettingsRepository,
//                                  userManager: self.userManager) }
//    }
// }
//
//// MARK: AutoFill
//
// extension SharedUseCasesContainer {
//    var mapLoginItem: Factory<any MapLoginItemUseCase> {
//        self { MapLoginItem() }
//    }
//
//    var indexAllLoginItems: Factory<any IndexAllLoginItemsUseCase> {
//        self { IndexAllLoginItems(userManager: self.userManager,
//                                  itemRepository: self.itemRepository,
//                                  shareRepository: self.shareRepository,
//                                  localAccessDatasource: RepositoryContainer.shared.localAccessDatasource(),
//                                  credentialManager: self.credentialManager,
//                                  mapLoginItem: self.mapLoginItem(),
//                                  symmetricKeyProvider: self.symmetricKeyProvider,
//                                  logManager: self.logManager) }
//    }
//
//    var unindexAllLoginItems: Factory<any UnindexAllLoginItemsUseCase> {
//        self { UnindexAllLoginItems(manager: self.credentialManager) }
//    }
// }
//
//// MARK: Spotlight
//
// extension SharedUseCasesContainer {
//    var indexItemsForSpotlight: Factory<any IndexItemsForSpotlightUseCase> {
//        self { IndexItemsForSpotlight(userManager: self.userManager,
//                                      itemRepository: self.itemRepository,
//                                      datasource: RepositoryContainer.shared
//                                          .localSpotlightVaultDatasource(),
//                                      logManager: self.logManager) }
//    }
// }
//
//// MARK: Vault
//
// extension SharedUseCasesContainer {
//    var processVaultSyncEvent: Factory<any ProcessVaultSyncEventUseCase> {
//        self { ProcessVaultSyncEvent() }
//    }
//
//    @MainActor
//    var getMainVault: Factory<any GetMainVaultUseCase> {
//        self { GetMainVault(appContentManager: self.appContentManager) }
//    }
//
//    @MainActor
//    var fullContentSync: Factory<any FullContentSyncUseCase> {
//        self { FullContentSync(syncEventLoop: ServiceContainer.shared.syncEventLoop(),
//                               appContentManager: self.appContentManager) }
//    }
// }
//
//// MARK: - Feature Flags
//
// extension SharedUseCasesContainer {
//    var getFeatureFlagStatus: Factory<any GetFeatureFlagStatusUseCase> {
//        self {
//            GetFeatureFlagStatus(repository: RepositoryContainer.shared.featureFlagsRepository())
//        }
//    }
// }
//
//// MARK: TOTP
//
// extension SharedUseCasesContainer {
//    var sanitizeTotpUriForEditing: Factory<any SanitizeTotpUriForEditingUseCase> {
//        self { SanitizeTotpUriForEditing() }
//    }
//
//    var sanitizeTotpUriForSaving: Factory<any SanitizeTotpUriForSavingUseCase> {
//        self { SanitizeTotpUriForSaving() }
//    }
//
//    var generateTotpToken: Factory<any GenerateTotpTokenUseCase> {
//        self { GenerateTotpToken(totpService: ServiceContainer.shared.totpService()) }
//    }
// }
//
//// MARK: Rust Utils
//
// extension SharedUseCasesContainer {
//    var generatePassword: Factory<any GeneratePasswordUseCase> {
//        self { GeneratePassword() }
//    }
//
//    var generateRandomWords: Factory<any GenerateRandomWordsUseCase> {
//        self { GenerateRandomWords() }
//    }
//
//    var generatePassphrase: Factory<any GeneratePassphraseUseCase> {
//        self { GeneratePassphrase() }
//    }
//
//    var getPasswordStrength: Factory<any GetPasswordStrengthUseCase> {
//        self { GetPasswordStrength() }
//    }
//
//    var generateUsername: Factory<any GenerateUsernameUseCase> {
//        self { GenerateUsername() }
//    }
// }
//
//// MARK: Data
//
// extension SharedUseCasesContainer {
//    var revokeCurrentSession: Factory<any RevokeCurrentSessionUseCase> {
//        self { RevokeCurrentSession(networkRepository: RepositoryContainer.shared.networkRepository(),
//                                    userManager: self.userManager) }
//    }
//
//    var deleteLocalDataBeforeFullSync: Factory<any DeleteLocalDataBeforeFullSyncUseCase> {
//        self { DeleteLocalDataBeforeFullSync(itemRepository: self.itemRepository,
//                                             shareRepository: self.shareRepository,
//                                             shareKeyRepository: RepositoryContainer.shared
//                                                 .shareKeyRepository(),
//                                             folderKeyDatasource: RepositoryContainer.shared
//                                                 .localFolderKeyDatasource(),
//                                             folderRepository: RepositoryContainer.shared
//                                                 .folderRepository()) }
//    }
//
//    @MainActor
//    var logOutUser: Factory<any LogOutUserUseCase> {
//        self {
//            LogOutUser(userManager: self.userManager,
//                       syncEventLoop: ServiceContainer.shared.syncEventLoop(),
//                       preferencesManager: self.preferencesManager,
//                       removeUserLocalData: self.removeUserLocalData(),
//                       featureFlagsRepository: RepositoryContainer.shared.featureFlagsRepository(),
//                       passMonitorRepository: self.passMonitorRepository,
//                       accessRepository: self.accessRepository,
//                       appContentManager: self.appContentManager,
//                       apiManager: self.apiManager,
//                       authManager: self.authManager,
//                       credentialManager: ServiceContainer.shared.credentialManager(),
//                       switchUser: self.switchUser())
//        }
//    }
//
//    var getUserUiModels: Factory<any GetUserUiModelsUseCase> {
//        self { GetUserUiModels(userManager: self.userManager,
//                               localAccessDatasource: RepositoryContainer.shared.localAccessDatasource()) }
//    }
//
//    var decryptOrganizationKey: Factory<any DecryptOrganizationKeyUseCase> {
//        self { DecryptOrganizationKey(repository: self.organizationRepository) }
//    }
//
//    var decryptGroupKey: Factory<any DecryptGroupKeyUseCase> {
//        self { DecryptGroupKey(decryptOrganizationKey: self.decryptOrganizationKey()) }
//    }
//
//    var dedupShare: Factory<any DedupShareUseCase> {
//        self { DedupShare() }
//    }
//
//    var getOrganizationSettings: Factory<any GetOrganizationSettingsUseCase> {
//        self { GetOrganizationSettings(accessRepository: self.accessRepository,
//                                       organizationRepository: self.organizationRepository) }
//    }
// }
//
//// MARK: - Items
//
// extension SharedUseCasesContainer {
//    var pinItems: Factory<any PinItemsUseCase> {
//        self { PinItems(itemRepository: self.itemRepository) }
//    }
//
//    var unpinItems: Factory<any UnpinItemsUseCase> {
//        self { UnpinItems(itemRepository: self.itemRepository) }
//    }
//
//    var canEditItem: Factory<any CanEditItemUseCase> {
//        self { CanEditItem() }
//    }
//
//    var getActiveLoginItems: Factory<any GetActiveLoginItemsUseCase> {
//        self { GetActiveLoginItems(symmetricKeyProvider: DataContainer.shared.symmetricKeyProvider(),
//                                   repository: self.itemRepository) }
//    }
//
//    var parseCsvLogins: Factory<any ParseCsvLoginsUseCase> {
//        self { ParseCsvLogins() }
//    }
//
//    var createVaultAndImportLogins: Factory<any CreateVaultAndImportLoginsUseCase> {
//        self { CreateVaultAndImportLogins(shareRepository: self.shareRepository,
//                                          itemRepository: self.itemRepository) }
//    }
// }
//
//// MARK: - Rust Validators
//
// extension SharedUseCasesContainer {
//    var validateAliasPrefix: Factory<any ValidateAliasPrefixUseCase> {
//        self { ValidateAliasPrefix() }
//    }
//
//    var getRootDomain: Factory<any GetRootDomainUseCase> {
//        // Register as `cached` because the list of root domain is long
//        self { GetRootDomain() }
//            .cached
//    }
//
//    var matchUrls: Factory<any MatchUrlsUseCase> {
//        self { MatchUrls(getRootDomain: self.getRootDomain()) }
//    }
// }
//
//// MARK: - User
//
// extension SharedUseCasesContainer {
//    var refreshUserSettings: Factory<any RefreshUserSettingsUseCase> {
//        self { RefreshUserSettings(userSettingsProtocol: self.userSettingsRepository)
//        }
//    }
//
//    var toggleSentinel: Factory<any ToggleSentinelUseCase> {
//        self { ToggleSentinel(userSettingsProtocol: self.userSettingsRepository,
//                              userManager: self.userManager) }
//    }
//
//    var getSentinelStatus: Factory<any GetSentinelStatusUseCase> {
//        self { GetSentinelStatus(userSettingsProtocol: self.userSettingsRepository,
//                                 userManager: self.userManager) }
//    }
//
//    var removeUserLocalData: Factory<any RemoveUserLocalDataUseCase> {
//        self {
//            let container = RepositoryContainer.shared
//            return RemoveUserLocalData(accessDatasource: container.localAccessDatasource(),
//                                       itemDatasource: container.localItemDatasource(),
//                                       itemReadEventDatasource: container.localItemReadEventDatasource(),
//                                       organizationDatasource: container.localOrganizationDatasource(),
//                                       searchEntryDatasource: container.localSearchEntryDatasource(),
//                                       shareDatasource: container.localShareDatasource(),
//                                       shareEventIdDatasource: container.localShareEventIDDatasource(),
//                                       shareKeyDatasource: container.localShareKeyDatasource(),
//                                       spotlightVaultDatasource: container.localSpotlightVaultDatasource(),
//                                       telemetryEventDatasource: container.localTelemetryEventDatasource(),
//                                       userDataDatasource: container.localUserDataDatasource(),
//                                       userPreferencesDatasource: container.userPreferencesDatasource(),
//                                       inAppNotificationDatasource: container.localInAppNotificationDatasource(),
//                                       passwordDatasource: container.localPasswordDatasource(),
//                                       userInviteDatasource: container.localInviteDatasource(),
//                                       userEventIdDatasource: container.localUserEventIdDatasource(),
//                                       coreEventIdDatasource: container.localCoreEventIdDatasource(),
//                                       folderDatasource: container.localFolderDatasource(),
//                                       folderKeysDatasource: container.localFolderKeyDatasource())
//        }
//    }
//
//    @MainActor
//    var switchUser: Factory<any SwitchUserUseCase> {
//        self { SwitchUser(userManager: self.userManager,
//                          appContentManager: self.appContentManager,
//                          preferencesManager: self.preferencesManager,
//                          apiManager: self.apiManager,
//                          syncEventLoop: self.syncEventLoop,
//                          refreshFeatureFlags: self.refreshFeatureFlags(),
//                          inviteRepository: self.inviteRepository) }
//    }
//
//    @MainActor
//    var addAndSwitchToNewUserAccount: Factory<any AddAndSwitchToNewUserAccountUseCase> {
//        self { AddAndSwitchToNewUserAccount(syncEventLoop: self.syncEventLoop,
//                                            userManager: self.userManager,
//                                            authManager: self.authManager,
//                                            preferencesManager: self.preferencesManager,
//                                            apiManager: self.apiManager,
//                                            fullContentSync: self.fullContentSync(),
//                                            refreshFeatureFlags: self.refreshFeatureFlags(),
//                                            inviteRepository: self.inviteRepository) }
//    }
//
//    @MainActor
//    var logOutAllAccounts: Factory<any LogOutAllAccountsUseCase> {
//        self { LogOutAllAccounts(userManager: self.userManager,
//                                 syncEventLoop: self.syncEventLoop,
//                                 preferencesManager: self.preferencesManager,
//                                 removeUserLocalData: self.removeUserLocalData(),
//                                 featureFlagsRepository: RepositoryContainer.shared.featureFlagsRepository(),
//                                 passMonitorRepository: self.passMonitorRepository,
//                                 appContentManager: self.appContentManager,
//                                 apiManager: self.apiManager,
//                                 authManager: self.authManager,
//                                 credentialManager: ServiceContainer.shared.credentialManager(),
//                                 keychain: self.keychain) }
//    }
//
//    var getLastEventIdIfNotExist: Factory<any GetLastEventIdIfNotExistUseCase> {
//        self {
//            let container = RepositoryContainer.shared
//            return GetLastEventIdIfNotExist(localDatasource: container.localUserEventIdDatasource(),
//                                            remoteDatasource: container.remoteUserEventsDatasource())
//        }
//    }
//
//    var refreshUserData: Factory<any RefreshUserDataUseCase> {
//        self { RefreshUserData(remoteDatasource: RepositoryContainer.shared.remoteUserDataDatasource(),
//                               userManager: self.userManager) }
//    }
// }
//
//// MARK: Passkey
//
// extension SharedUseCasesContainer {
//    var passkeyManagerProvider: Factory<any PasskeyManagerProvider> {
//        self { PasskeyManagerProviderImpl() }
//    }
//
//    var createPasskey: Factory<any CreatePasskeyUseCase> {
//        self { CreatePasskey(managerProvider: self.passkeyManagerProvider()) }
//    }
//
//    var resolvePasskeyChallenge: Factory<any ResolvePasskeyChallengeUseCase> {
//        self { ResolvePasskeyChallenge(managerProvider: self.passkeyManagerProvider()) }
//    }
// }
//
//// MARK: Preferences
//
// extension SharedUseCasesContainer {
//    var getAppPreferences: Factory<any GetAppPreferencesUseCase> {
//        self { GetAppPreferences(manager: self.preferencesManager) }
//    }
//
//    var getSharedPreferences: Factory<any GetSharedPreferencesUseCase> {
//        self { GetSharedPreferences(manager: self.preferencesManager) }
//    }
//
//    var getUserPreferences: Factory<any GetUserPreferencesUseCase> {
//        self { GetUserPreferences(manager: self.preferencesManager) }
//    }
//
//    var updateAppPreferences: Factory<any UpdateAppPreferencesUseCase> {
//        self { UpdateAppPreferences(manager: self.preferencesManager) }
//    }
//
//    var updateSharedPreferences: Factory<any UpdateSharedPreferencesUseCase> {
//        self { UpdateSharedPreferences(manager: self.preferencesManager) }
//    }
//
//    var updateUserPreferences: Factory<any UpdateUserPreferencesUseCase> {
//        self { UpdateUserPreferences(manager: self.preferencesManager) }
//    }
// }
//
//// MARK: Misc
//
// extension SharedUseCasesContainer {
//    var copyToClipboard: Factory<any CopyToClipboardUseCase> {
//        self { CopyToClipboard(getSharedPreferences: self.getSharedPreferences()) }
//    }
//
//    var applyAppMigration: Factory<any ApplyAppMigrationUseCase> {
//        self { ApplyAppMigration(dataMigrationManager: ServiceContainer.shared.dataMigrationManager(),
//                                 userManager: self.userManager,
//                                 authManager: self.authManager,
//                                 itemDatasource: RepositoryContainer.shared.localItemDatasource(),
//                                 searchEntryDatasource: RepositoryContainer.shared
//                                     .localSearchEntryDatasource(),
//                                 shareKeyDatasource: RepositoryContainer.shared.localShareKeyDatasource(),
//                                 logManager: self.logManager) }
//    }
// }
//
//// MARK: - Dark web monitor
//
// extension SharedUseCasesContainer {
//    var getCustomEmailSuggestion: Factory<any GetCustomEmailSuggestionUseCase> {
//        self { GetCustomEmailSuggestion(itemRepository: self.itemRepository,
//                                        symmetricKeyProvider: self.symmetricKeyProvider,
//                                        validateEmailUseCase: self.validateEmail()) }
//    }
//
//    var validateEmail: Factory<any ValidateEmailUseCase> {
//        self { ValidateEmail() }
//    }
//
//    var getAllAliases: Factory<any GetAllAliasesUseCase> {
//        self { GetAllAliases(itemRepository: self.itemRepository) }
//    }
//
//    var sendUserMonitoringStats: Factory<any SendUserMonitoringStatsUseCase> {
//        self {
//            SendUserMonitoringStats(passMonitorRepository: self.passMonitorRepository,
//                                    accessRepository: self.accessRepository,
//                                    userManager: self.userManager,
//                                    storage: kSharedUserDefaults)
//        }
//    }
// }
//
//// MARK: - Flags
//
// extension SharedUseCasesContainer {
//    var refreshFeatureFlags: Factory<any RefreshFeatureFlagsUseCase> {
//        self { RefreshFeatureFlags(repository: RepositoryContainer.shared.featureFlagsRepository(),
//                                   apiServicing: self.apiManager,
//                                   userManager: self.userManager,
//                                   logManager: self.logManager) }
//    }
// }
//
//// MARK: - File attachments
//
// extension SharedUseCasesContainer {
//    var generateDatedFileName: Factory<any GenerateDatedFileNameUseCase> {
//        self { GenerateDatedFileName() }
//    }
//
//    var writeToUrl: Factory<any WriteToUrlUseCase> {
//        self { WriteToUrl() }
//    }
//
//    var getFileSize: Factory<any GetFileSizeUseCase> {
//        self { GetFileSize() }
//    }
//
//    var getMimeType: Factory<any GetMimeTypeUseCase> {
//        self { GetMimeType() }
//    }
//
//    var getFileGroup: Factory<any GetFileGroupUseCase> {
//        self { GetFileGroup() }
//    }
//
//    var formatFileAttachmentSize: Factory<any FormatFileAttachmentSizeUseCase> {
//        self { FormatFileAttachmentSize() }
//    }
//
//    var generateFileTempUrl: Factory<any GenerateFileTempUrlUseCase> {
//        self { GenerateFileTempUrl(sanitizeFileName: self.sanitizeFileName()) }
//    }
//
//    var downloadAndDecryptFile: Factory<any DownloadAndDecryptFileUseCase> {
//        self { DownloadAndDecryptFile(generateFileTempUrl: self.generateFileTempUrl(),
//                                      shareRepository: self.shareRepository,
//                                      keyManager: RepositoryContainer.shared.passKeyManager(),
//                                      apiService: ToolingContainer.shared.apiServiceLite()) }
//    }
//
//    var getFilesToLink: Factory<any GetFilesToLinkUseCase> {
//        self { GetFilesToLink() }
//    }
//
//    var clearCacheForLoggedOutUsers: Factory<any ClearCacheForLoggedOutUsersUseCase> {
//        self {
//            ClearCacheForLoggedOutUsers(datasource: RepositoryContainer.shared.localUserDataDatasource())
//        }
//    }
//
//    var sanitizeFileName: Factory<any SanitizeFileNameUseCase> {
//        self { SanitizeFileName() }
//    }
// }
