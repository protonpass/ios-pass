// The Swift Programming Language
// https://docs.swift.org/swift-book

import Client
import Core
import FactoryKit
import UseCases

final class UseCasesContainer: SharedContainer, AutoRegistering {
    static let shared = UseCasesContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .shared
    }
}

// MARK: - Computed properties

private extension UseCasesContainer {
    var logManager: any LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }

    @MainActor
    var shareInviteService: any ShareInviteServiceProtocol {
        ServiceContainer.shared.shareInviteService()
    }

    var userManager: any UserManagerProtocol {
        SharedServiceContainer.shared.userManager()
    }

    var itemRepository: any ItemRepositoryProtocol {
        SharedRepositoryContainer.shared.itemRepository()
    }

    var shareRepository: any ShareRepositoryProtocol {
        SharedRepositoryContainer.shared.shareRepository()
    }

    var symmetricKeyProvider: any SymmetricKeyProvider {
        SharedDataContainer.shared.symmetricKeyProvider()
    }

    var localSpotlightVaultDatasource: any LocalSpotlightVaultDatasourceProtocol {
        SharedRepositoryContainer.shared.localSpotlightVaultDatasource()
    }

    var accessRepository: any AccessRepositoryProtocol {
        SharedRepositoryContainer.shared.accessRepository()
    }

    var inviteRepository: any FullInviteRepositoryProtocol {
        SharedRepositoryContainer.shared.inviteRepository()
    }

    var publicKeyRepository: any PublicKeyRepositoryProtocol {
        SharedRepositoryContainer.shared.publicKeyRepository()
    }

    var appContentManager: any AppContentManagerProtocol {
        SharedServiceContainer.shared.appContentManager()
    }

    var passMonitorRepository: any PassMonitorRepositoryProtocol {
        SharedRepositoryContainer.shared.passMonitorRepository()
    }

    var extraPasswordRepository: any ExtraPasswordRepositoryProtocol {
        RepositoryContainer.shared.extraPasswordRepository()
    }

    var passKeyManager: any PassKeyManagerProtocol {
        SharedRepositoryContainer.shared.passKeyManager()
    }

    var secureLinkManager: any SecureLinkManagerProtocol {
        ServiceContainer.shared.secureLinkManager()
    }

    var remoteSecureLinkDatasource: any RemoteSecureLinkDatasourceProtocol {
        SharedRepositoryContainer.shared.remoteSecureLinkDatasource()
    }

    var localAccessDatasource: any LocalAccessDatasourceProtocol {
        SharedRepositoryContainer.shared.localAccessDatasource()
    }

    var apiManager: any APIManagerProtocol {
        SharedToolingContainer.shared.apiManager()
    }
}

// MARK: User report

extension UseCasesContainer {
    var sendUserBugReport: Factory<any SendUserBugReportUseCase> {
        self { SendUserBugReport(reportRepository: RepositoryContainer.shared.reportRepository(),
                                 createLogsFile: self.createLogsFile()) }
    }
}

// MARK: Logs

extension UseCasesContainer {
    var extractLogsToFile: Factory<any ExtractLogsToFileUseCase> {
        self { ExtractLogsToFile(logFormatter: SharedToolingContainer.shared.logFormatter()) }
    }

    var getLogEntries: Factory<any GetLogEntriesUseCase> {
        self { GetLogEntries(mainAppLogManager: LogManager(module: .hostApp),
                             autofillLogManager: LogManager(module: .autoFillExtension),
                             shareLogManager: LogManager(module: .shareExtension),
                             actionLogManager: LogManager(module: .actionExtension)) }
    }

    var createLogsFile: Factory<any CreateLogsFileUseCase> {
        self { CreateLogsFile(extractLogsToFile: self.extractLogsToFile(),
                              getLogEntries: self.getLogEntries()) }
    }
}

// MARK: - Sharing

extension UseCasesContainer {
    var createAndMoveItemToNewVault: Factory<any CreateAndMoveItemToNewVaultUseCase> {
        self { CreateAndMoveItemToNewVault(createVault: self.createVault(),
                                           moveItemsBetweenContainers: self.moveItemsBetweenContainers(),
                                           appContentManager: self.appContentManager) }
    }

    var getCurrentShareInviteInformations: Factory<any GetCurrentShareInviteInformationsUseCase> {
        self { @MainActor in GetCurrentShareInviteInformations(shareInviteService: self.shareInviteService)
        }
    }

    var setShareInviteVault: Factory<any SetShareInviteVaultUseCase> {
        self { @MainActor in SetShareInviteVault(shareInviteService: self.shareInviteService,
                                                 getVaultItemCount: self.getVaultItemCount()) }
    }

    var setShareInvitesAndKeys: Factory<any SetShareInvitesAndKeysUseCase> {
        self { SetShareInvitesAndKeys(shareInviteService: self.shareInviteService,
                                      getEmailPublicKeyUseCase: self.getEmailPublicKey()) }
    }

    var setShareInviteRole: Factory<any SetShareInviteRoleUseCase> {
        self { @MainActor in SetShareInviteRole(shareInviteService: self.shareInviteService) }
    }

    var sendShareInvite: Factory<any SendShareInviteUseCase> {
        self { SendShareInvite(createAndMoveItemToNewVault: self.createAndMoveItemToNewVault(),
                               makeUnsignedSignatureForVaultSharing: self
                                   .makeUnsignedSignatureForVaultSharing(),
                               shareInviteService: self.shareInviteService,
                               passKeyManager: SharedRepositoryContainer.shared.passKeyManager(),
                               shareInviteRepository: self.inviteRepository,
                               userManager: self.userManager,
                               syncEventLoop: SharedServiceContainer.shared.syncEventLoop()) }
    }

    var promoteNewUserInvite: Factory<any PromoteNewUserInviteUseCase> {
        self { PromoteNewUserInvite(publicKeyRepository: self.publicKeyRepository,
                                    passKeyManager: SharedRepositoryContainer.shared.passKeyManager(),
                                    shareInviteRepository: self.inviteRepository,
                                    userManager: self.userManager) }
    }

    var getEmailPublicKey: Factory<any GetEmailPublicKeyUseCase> {
        self { GetEmailPublicKey(publicKeyRepository: self.publicKeyRepository) }
    }

    var checkAddressesForInvite: Factory<any CheckAddressesForInviteUseCase> {
        self { CheckAddressesForInvite(userManager: self.userManager,
                                       accessRepository: self.accessRepository,
                                       organizationRepository: SharedRepositoryContainer.shared
                                           .organizationRepository(),
                                       shareInviteRepository: self.inviteRepository) }
    }

    var leaveShare: Factory<any LeaveShareUseCase> {
        self { LeaveShare(appContentManager: self.appContentManager) }
    }

    var getUsersLinkedToShare: Factory<any GetUsersLinkedToShareUseCase> {
        self { GetUsersLinkedToShare(repository: self.shareRepository) }
    }

    var getPendingInvitationsForShare: Factory<any GetPendingInvitationsForShareUseCase> {
        self { GetPendingInvitationsForShare(repository: self.inviteRepository) }
    }

    var updateUserShareRole: Factory<any UpdateUserShareRoleUseCase> {
        self { UpdateUserShareRole(repository: self.shareRepository) }
    }

    var revokeUserShareAccess: Factory<any RevokeUserShareAccessUseCase> {
        self { RevokeUserShareAccess(repository: self.shareRepository) }
    }

    var getUserShareStatus: Factory<any GetUserShareStatusUseCase> {
        self {
            GetUserShareStatus(accessRepository: self.accessRepository)
        }
    }

    var canUserPerformActionOnVault: Factory<any CanUserPerformActionOnVaultUseCase> {
        self {
            CanUserPerformActionOnVault(accessRepository: self.accessRepository,
                                        appContentManager: self.appContentManager)
        }
    }
}

// MARK: - Invites

extension UseCasesContainer {
    var getPendingUserInvitations: Factory<any GetPendingUserInvitationsUseCase> {
        self { GetPendingUserInvitations(repository: self.inviteRepository) }
    }

    var refreshInvitations: Factory<any RefreshInvitationsUseCase> {
        self { RefreshInvitations(inviteRepository: self.inviteRepository,
                                  userManager: self.userManager) }
    }

    var rejectInvitation: Factory<any RejectInvitationUseCase> {
        self { RejectInvitation(repository: self.inviteRepository,
                                userManager: self.userManager) }
    }

    var acceptInvitation: Factory<any AcceptInvitationUseCase> {
        self { AcceptInvitation(repository: self.inviteRepository,
                                userManager: self.userManager,
                                getEmailPublicKey: self.getEmailPublicKey(),
                                getInviteDecryptionKeys: self.getInviteDecryptionKeys(),
                                logManager: self.logManager) }
    }

    var decodeShareVaultInformation: Factory<any DecodeShareVaultInformationUseCase> {
        self { DecodeShareVaultInformation(getEmailPublicKey: self.getEmailPublicKey(),
                                           getInviteDecryptionKeys: self.getInviteDecryptionKeys(),
                                           logManager: self.logManager) }
    }

    var updateCachedInvitations: Factory<any UpdateCachedInvitationsUseCase> {
        self { UpdateCachedInvitations(repository: self.inviteRepository) }
    }

    var revokeInvitation: Factory<any RevokeInvitationUseCase> {
        self { RevokeInvitation(shareInviteRepository: self.inviteRepository) }
    }

    var revokeNewUserInvitation: Factory<any RevokeNewUserInvitationUseCase> {
        self {
            RevokeNewUserInvitation(shareInviteRepository: self.inviteRepository)
        }
    }

    var sendInviteReminder: Factory<any SendInviteReminderUseCase> {
        self { SendInviteReminder(shareInviteRepository: self.inviteRepository) }
    }

    var canUserTransferVaultOwnership: Factory<any CanUserTransferVaultOwnershipUseCase> {
        self { @MainActor in CanUserTransferVaultOwnership(appContentManager: self.appContentManager) }
    }

    var makeUnsignedSignatureForVaultSharing: Factory<any MakeUnsignedSignatureForVaultSharingUseCase> {
        self { MakeUnsignedSignatureForVaultSharing() }
    }

    var getInviteDecryptionKeys: Factory<any GetInviteDecryptionKeysUseCase> {
        self { GetInviteDecryptionKeys(userManager: self.userManager,
                                       groupRepository: SharedRepositoryContainer.shared.groupRepository(),
                                       decryptGroupKeys: SharedUseCasesContainer.shared.decryptGroupKey(),
                                       updateUserAddresses: self.updateUserAddresses()) }
    }
}

// MARK: - Vaults

extension UseCasesContainer {
    var getVaultItemCount: Factory<any GetVaultItemCountUseCase> {
        self { @MainActor in GetVaultItemCount(appContentManager: self.appContentManager) }
    }

    var transferVaultOwnership: Factory<any TransferVaultOwnershipUseCase> {
        self { TransferVaultOwnership(repository: self.shareRepository) }
    }

    var moveItemsBetweenContainers: Factory<any MoveItemsBetweenContainersUseCase> {
        self { @MainActor in
            MoveItemsBetweenContainers(repository: self.itemRepository,
                                       appContentManager: self.appContentManager)
        }
    }

    var trashSelectedItems: Factory<any TrashSelectedItemsUseCase> {
        self { TrashSelectedItems(repository: self.itemRepository) }
    }

    var restoreSelectedItems: Factory<any RestoreSelectedItemsUseCase> {
        self { RestoreSelectedItems(repository: self.itemRepository) }
    }

    var permanentlyDeleteSelectedItems: Factory<any PermanentlyDeleteSelectedItemsUseCase> {
        self { PermanentlyDeleteSelectedItems(repository: self.itemRepository) }
    }

    var createVault: Factory<any CreateVaultUseCase> {
        self { CreateVault(appContentManager: self.appContentManager,
                           repository: self.shareRepository) }
    }

    var reorganizeVaults: Factory<any ReorganizeVaultsUseCase> {
        self { ReorganizeVaults(userManager: self.userManager,
                                shareRepository: self.shareRepository) }
    }

    var checkVaultCreationAllowance: Factory<any CheckVaultCreationAllowanceUseCase> {
        self { CheckVaultCreationAllowance() }
    }
}

// MARK: Spotlight

extension UseCasesContainer {
    var getSpotlightVaults: Factory<any GetSpotlightVaultsUseCase> {
        self { GetSpotlightVaults(userManager: self.userManager,
                                  shareRepository: self.shareRepository,
                                  localSpotlightVaultDatasource: self
                                      .localSpotlightVaultDatasource) }
    }

    var updateSpotlightVaults: Factory<any UpdateSpotlightVaultsUseCase> {
        self { UpdateSpotlightVaults(userManager: self.userManager,
                                     datasource: self.localSpotlightVaultDatasource) }
    }
}

// MARK: - items

extension UseCasesContainer {
    var getAllPinnedItems: Factory<any GetAllPinnedItemsUseCase> {
        self { GetAllPinnedItems(itemRepository: self.itemRepository) }
    }

    var getSearchableItems: Factory<any GetSearchableItemsUseCase> {
        self { GetSearchableItems(itemRepository: self.itemRepository,
                                  shareRepository: self.shareRepository,
                                  getAllPinnedItems: self.getAllPinnedItems(),
                                  dedupShare: SharedUseCasesContainer.shared.dedupShare(),
                                  symmetricKeyProvider: self.symmetricKeyProvider) }
    }

    var getItemHistory: Factory<any GetItemHistoryUseCase> {
        self { GetItemHistory(itemRepository: self.itemRepository) }
    }

    var getItemContentFromBase64IDs: Factory<any GetItemContentFromBase64IDsUseCase> {
        self { GetItemContentFromBase64IDs(itemRepository: self.itemRepository,
                                           symmetricKeyProvider: self.symmetricKeyProvider) }
    }

    var generateSshKey: Factory<any GenerateSshKeyUseCase> {
        self { GenerateSshKey() }
    }
}

// MARK: - User

extension UseCasesContainer {
    var updateUserAddresses: Factory<any UpdateUserAddressesUseCase> {
        self { UpdateUserAddresses(userManager: self.userManager,
                                   apiServicing: self.apiManager) }
    }

    var refreshAccessAndMonitorState: Factory<any RefreshAccessAndMonitorStateUseCase> {
        self { RefreshAccessAndMonitorState(accessRepository: self.accessRepository,
                                            passMonitorRepository: self.passMonitorRepository,
                                            getAllAliases: SharedUseCasesContainer.shared.getAllAliases(),
                                            getBreachesForAlias: self.getBreachesForAlias(),
                                            stream: DataStreamContainer.shared.monitorStateStream()) }
    }

    var verifyProtonPassword: Factory<any VerifyProtonPasswordUseCase> {
        self { VerifyProtonPassword(userManager: self.userManager,
                                    doh: SharedToolingContainer.shared.doh(),
                                    appVer: SharedToolingContainer.shared.appVersion()) }
    }

    var enableExtraPassword: Factory<any EnableExtraPasswordUseCase> {
        self { EnableExtraPassword(repository: self.extraPasswordRepository) }
    }

    var disableExtraPassword: Factory<any DisableExtraPasswordUseCase> {
        self { DisableExtraPassword(repository: self.extraPasswordRepository,
                                    verifyExtraPassword: self.verifyExtraPassword()) }
    }

    var verifyExtraPassword: Factory<any VerifyExtraPasswordUseCase> {
        self { VerifyExtraPassword() }
    }

    var canAddNewAccount: Factory<any CanAddNewAccountUseCase> {
        self { CanAddNewAccount(localDatasource: self.localAccessDatasource,
                                remoteDatasource: SharedRepositoryContainer.shared.remoteAccessDatasource(),
                                authManager: SharedToolingContainer.shared.authManager()) }
    }

    var logOutExcessFreeAccounts: Factory<any LogOutExcessFreeAccountsUseCase> {
        self { LogOutExcessFreeAccounts(datasource: self.localAccessDatasource,
                                        logOutUser: SharedUseCasesContainer.shared.logOutUser()) }
    }

    // periphery:ignore
    var checkFlagForMultiUsers: Factory<any CheckFlagForMultiUsersUseCase> {
        self { CheckFlagForMultiUsers(apiServicing: self.apiManager) }
    }
}

// MARK: - Misc

extension UseCasesContainer {
    var getRustLibraryVersion: Factory<any GetRustLibraryVersionUseCase> {
        self { GetRustLibraryVersion() }
    }

    var enableAutoFill: Factory<any EnableAutoFillUseCase> {
        self { EnableAutoFill(router: SharedRouterContainer.shared.mainUIKitSwiftUIRouter(),
                              credentialManager: SharedServiceContainer.shared.credentialManager()) }
    }

    var makeAccountSettingsUrl: Factory<any MakeAccountSettingsUrlUseCase> {
        self { MakeAccountSettingsUrl(doh: SharedToolingContainer.shared.doh()) }
    }
}

// MARK: - App

extension UseCasesContainer {
    var shouldDisplayUpgradeAppBanner: Factory<any ShouldDisplayUpgradeAppBannerUseCase> {
        self { ShouldDisplayUpgradeAppBanner(accessRepository: self.accessRepository,
                                             bundle: .main,
                                             userDefaults: .standard) }
    }

    var firstRunDetector: Factory<any FirstRunDetectorProtocol> {
        self { FirstRunDetector(userDefaults: kSharedUserDefaults, bundle: .main) }
    }

    var postbackConversionValue: Factory<any PostbackConversionValueUseCase> {
        self { PostbackConversionValue() }
    }
}

// MARK: - Security

extension UseCasesContainer {
    var getAllSecurityAffectedLogins: Factory<any GetAllSecurityAffectedLoginsUseCase> {
        self {
            GetAllSecurityAffectedLogins(passMonitorRepository: self.passMonitorRepository,
                                         symmetricKeyProvider: SharedDataContainer.shared
                                             .nonSendableSymmetricKeyProvider(),
                                         getPasswordStrength: SharedUseCasesContainer.shared.getPasswordStrength())
        }
    }

    var getLoginSecurityIssues: Factory<any GetLoginSecurityIssuesUseCase> {
        self {
            GetLoginSecurityIssues(passMonitorRepository: self.passMonitorRepository)
        }
    }

    var toggleItemMonitoring: Factory<any ToggleItemMonitoringUseCase> {
        self {
            ToggleItemMonitoring(itemRepository: self.itemRepository)
        }
    }

    var getAllAliasMonitorInfos: Factory<any GetAllAliasMonitorInfoUseCase> {
        self { GetAllAliasMonitorInfos(getAllAliasesUseCase: SharedUseCasesContainer.shared.getAllAliases(),
                                       repository: self.passMonitorRepository) }
    }

    var addCustomEmailToMonitoring: Factory<any AddCustomEmailToMonitoringUseCase> {
        self { AddCustomEmailToMonitoring(repository: self.passMonitorRepository) }
    }

    var getAllCustomEmails: Factory<any GetAllCustomEmailsUseCase> {
        self { GetAllCustomEmails(repository: self.passMonitorRepository) }
    }

    var removeEmailFromBreachMonitoring: Factory<any RemoveEmailFromBreachMonitoringUseCase> {
        self { RemoveEmailFromBreachMonitoring(repository: self.passMonitorRepository) }
    }

    var verifyCustomEmail: Factory<any VerifyCustomEmailUseCase> {
        self { VerifyCustomEmail(repository: self.passMonitorRepository) }
    }

    var toggleMonitoringForAlias: Factory<any ToggleMonitoringForAliasUseCase> {
        self { ToggleMonitoringForAlias(repository: self.passMonitorRepository,
                                        getAllAliasMonitorInfo: self.getAllAliasMonitorInfos()) }
    }

    var toggleMonitoringForCustomEmail: Factory<any ToggleMonitoringForCustomEmailUseCase> {
        self { ToggleMonitoringForCustomEmail(repository: self.passMonitorRepository) }
    }

    var toggleMonitoringForProtonAddress: Factory<any ToggleMonitoringForProtonAddressUseCase> {
        self { ToggleMonitoringForProtonAddress(repository: self.passMonitorRepository) }
    }

    var getItemsLinkedToBreach: Factory<any GetItemsLinkedToBreachUseCase> {
        self { GetItemsLinkedToBreach(symmetricKeyProvider: self.symmetricKeyProvider,
                                      repository: self.itemRepository) }
    }

    var getBreachesForAlias: Factory<any GetBreachesForAliasUseCase> {
        self { GetBreachesForAlias(repository: self.passMonitorRepository) }
    }
}

// MARK: - Organization

extension UseCasesContainer {
    var overrideSecuritySettings: Factory<any OverrideSecuritySettingsUseCase> {
        self { OverrideSecuritySettings(preferencesManager: SharedToolingContainer.shared.preferencesManager()) }
    }

    var addItemReadEvent: Factory<any AddItemReadEventUseCase> {
        self { AddItemReadEvent(eventRepository: SharedRepositoryContainer.shared.itemReadEventRepository(),
                                accessRepository: self.accessRepository,
                                userManager: self.userManager,
                                logManager: self.logManager) }
    }
}

// MARK: - Secure link

extension UseCasesContainer {
    var createSecureLink: Factory<any CreateSecureLinkUseCase> {
        self { CreateSecureLink(datasource: self.remoteSecureLinkDatasource,
                                getSecureLinkKeys: self.getSecureLinkKeys(),
                                userManager: self.userManager,
                                manager: self.secureLinkManager) }
    }

    var getSecureLinkKeys: Factory<any GetSecureLinkKeysUseCase> {
        self { GetSecureLinkKeys(passKeyManager: self.passKeyManager,
                                 userManager: self.userManager) }
    }

    var deleteSecureLink: Factory<any DeleteSecureLinkUseCase> {
        self { DeleteSecureLink(datasource: self.remoteSecureLinkDatasource,
                                userManager: self.userManager,
                                manager: self.secureLinkManager) }
    }

    var recreateSecureLink: Factory<any RecreateSecureLinkUseCase> {
        self { RecreateSecureLink(passKeyManager: self.passKeyManager,
                                  userManager: self.userManager) }
    }

    var deleteAllInactiveSecureLinks: Factory<any DeleteAllInactiveSecureLinksUseCase> {
        self {
            DeleteAllInactiveSecureLinks(datasource: self.remoteSecureLinkDatasource,
                                         userManager: self.userManager,
                                         manager: self.secureLinkManager)
        }
    }
}

/// mark shared
///
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

    @MainActor
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

    var organizationRepository: any OrganizationRepositoryProtocol {
        SharedRepositoryContainer.shared.organizationRepository()
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
                                             organizationRepository: self.organizationRepository) }
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

    // periphery:ignore
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

    @MainActor
    var getMainVault: Factory<any GetMainVaultUseCase> {
        self { GetMainVault(appContentManager: self.appContentManager) }
    }

    @MainActor
    var fullContentSync: Factory<any FullContentSyncUseCase> {
        self { FullContentSync(syncEventLoop: SharedServiceContainer.shared.syncEventLoop(),
                               appContentManager: self.appContentManager) }
    }
}

// MARK: - Feature Flags

extension SharedUseCasesContainer {
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

// MARK: Rust Utils

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

    var generateUsername: Factory<any GenerateUsernameUseCase> {
        self { GenerateUsername() }
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
                                                 .shareKeyRepository(),
                                             folderKeyDatasource: SharedRepositoryContainer.shared
                                                 .localFolderKeyDatasource(),
                                             folderRepository: SharedRepositoryContainer.shared
                                                 .folderRepository()) }
    }

    @MainActor
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

    var decryptOrganizationKey: Factory<any DecryptOrganizationKeyUseCase> {
        self { DecryptOrganizationKey(repository: self.organizationRepository) }
    }

    var decryptGroupKey: Factory<any DecryptGroupKeyUseCase> {
        self { DecryptGroupKey(decryptOrganizationKey: self.decryptOrganizationKey()) }
    }

    var dedupShare: Factory<any DedupShareUseCase> {
        self { DedupShare() }
    }

    var getOrganizationSettings: Factory<any GetOrganizationSettingsUseCase> {
        self { GetOrganizationSettings(accessRepository: self.accessRepository,
                                       organizationRepository: self.organizationRepository) }
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

    var parseCsvLogins: Factory<any ParseCsvLoginsUseCase> {
        self { ParseCsvLogins() }
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
                                       inAppNotificationDatasource: container.localInAppNotificationDatasource(),
                                       passwordDatasource: container.localPasswordDatasource(),
                                       userInviteDatasource: container.localInviteDatasource(),
                                       userEventIdDatasource: container.localUserEventIdDatasource(),
                                       coreEventIdDatasource: container.localCoreEventIdDatasource(),
                                       folderDatasource: container.localFolderDatasource(),
                                       folderKeysDatasource: container.localFolderKeyDatasource())
        }
    }

    @MainActor
    var switchUser: Factory<any SwitchUserUseCase> {
        self { SwitchUser(userManager: self.userManager,
                          appContentManager: self.appContentManager,
                          preferencesManager: self.preferencesManager,
                          apiManager: self.apiManager,
                          syncEventLoop: self.syncEventLoop,
                          refreshFeatureFlags: self.refreshFeatureFlags(),
                          inviteRepository: self.inviteRepository) }
    }

    @MainActor
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

    @MainActor
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

    var getLastEventIdIfNotExist: Factory<any GetLastEventIdIfNotExistUseCase> {
        self {
            let container = SharedRepositoryContainer.shared
            return GetLastEventIdIfNotExist(localDatasource: container.localUserEventIdDatasource(),
                                            remoteDatasource: container.remoteUserEventsDatasource())
        }
    }

    var refreshUserData: Factory<any RefreshUserDataUseCase> {
        self { RefreshUserData(remoteDatasource: SharedRepositoryContainer.shared.remoteUserDataDatasource(),
                               userManager: self.userManager) }
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
        self { GenerateFileTempUrl(sanitizeFileName: self.sanitizeFileName()) }
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

    var sanitizeFileName: Factory<any SanitizeFileNameUseCase> {
        self { SanitizeFileName() }
    }
}
