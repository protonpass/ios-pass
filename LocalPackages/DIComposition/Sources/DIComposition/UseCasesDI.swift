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
import FactoryKit
import UseCases

public final class UseCasesContainer: SharedContainer, AutoRegistering {
    public static let shared = UseCasesContainer()
    public let manager = ContainerManager()

    public func autoRegister() {
        manager.defaultScope = .shared
    }
}

// MARK: - Computed properties

private extension UseCasesContainer {
    var logManager: any LogManagerProtocol {
        ToolingContainer.shared.logManager()
    }

    @MainActor
    var shareInviteService: any ShareInviteServiceProtocol {
        ServiceContainer.shared.shareInviteService()
    }

    var userManager: any UserManagerProtocol {
        ServiceContainer.shared.userManager()
    }

    var itemRepository: any ItemRepositoryProtocol {
        RepositoryContainer.shared.itemRepository()
    }

    var shareRepository: any ShareRepositoryProtocol {
        RepositoryContainer.shared.shareRepository()
    }

    var symmetricKeyProvider: any SymmetricKeyProvider {
        DataContainer.shared.symmetricKeyProvider()
    }

    var localSpotlightVaultDatasource: any LocalSpotlightVaultDatasourceProtocol {
        RepositoryContainer.shared.localSpotlightVaultDatasource()
    }

    var accessRepository: any AccessRepositoryProtocol {
        RepositoryContainer.shared.accessRepository()
    }

    var inviteRepository: any FullInviteRepositoryProtocol {
        RepositoryContainer.shared.inviteRepository()
    }

    var publicKeyRepository: any PublicKeyRepositoryProtocol {
        RepositoryContainer.shared.publicKeyRepository()
    }

    @MainActor
    var appContentManager: any AppContentManagerProtocol {
        ServiceContainer.shared.appContentManager()
    }

    var passMonitorRepository: any PassMonitorRepositoryProtocol {
        RepositoryContainer.shared.passMonitorRepository()
    }

    var extraPasswordRepository: any ExtraPasswordRepositoryProtocol {
        RepositoryContainer.shared.extraPasswordRepository()
    }

    var passKeyManager: any PassKeyManagerProtocol {
        RepositoryContainer.shared.passKeyManager()
    }

    var secureLinkManager: any SecureLinkManagerProtocol {
        ServiceContainer.shared.secureLinkManager()
    }

    var remoteSecureLinkDatasource: any RemoteSecureLinkDatasourceProtocol {
        RepositoryContainer.shared.remoteSecureLinkDatasource()
    }

    var localAccessDatasource: any LocalAccessDatasourceProtocol {
        RepositoryContainer.shared.localAccessDatasource()
    }

    var apiManager: any APIManagerProtocol {
        ToolingContainer.shared.apiManager()
    }
}

// MARK: User report

public extension UseCasesContainer {
    var sendUserBugReport: Factory<any SendUserBugReportUseCase> {
        self { SendUserBugReport(reportRepository: RepositoryContainer.shared.reportRepository(),
                                 createLogsFile: self.createLogsFile()) }
    }
}

// MARK: Logs

public extension UseCasesContainer {
    var extractLogsToFile: Factory<any ExtractLogsToFileUseCase> {
        self { ExtractLogsToFile(logFormatter: ToolingContainer.shared.logFormatter()) }
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

public extension UseCasesContainer {
    @MainActor
    var createAndMoveItemToNewVault: Factory<any CreateAndMoveItemToNewVaultUseCase> {
        self { CreateAndMoveItemToNewVault(createVault: self.createVault(),
                                           moveItemsBetweenContainers: self.moveItemsBetweenContainers(),
                                           appContentManager: self.appContentManager) }
    }

    @MainActor
    var getCurrentShareInviteInformations: Factory<any GetCurrentShareInviteInformationsUseCase> {
        self { GetCurrentShareInviteInformations(shareInviteService: self.shareInviteService)
        }
    }

    @MainActor
    var setShareInviteVault: Factory<any SetShareInviteVaultUseCase> {
        self { SetShareInviteVault(shareInviteService: self.shareInviteService,
                                   getVaultItemCount: self.getVaultItemCount()) }
    }

    @MainActor
    var setShareInvitesAndKeys: Factory<any SetShareInvitesAndKeysUseCase> {
        self { SetShareInvitesAndKeys(shareInviteService: self.shareInviteService,
                                      getEmailPublicKeyUseCase: self.getEmailPublicKey()) }
    }

    @MainActor
    var setShareInviteRole: Factory<any SetShareInviteRoleUseCase> {
        self { SetShareInviteRole(shareInviteService: self.shareInviteService) }
    }

    @MainActor
    var sendShareInvite: Factory<any SendShareInviteUseCase> {
        self { SendShareInvite(createAndMoveItemToNewVault: self.createAndMoveItemToNewVault(),
                               makeUnsignedSignatureForVaultSharing: self
                                   .makeUnsignedSignatureForVaultSharing(),
                               shareInviteService: self.shareInviteService,
                               passKeyManager: RepositoryContainer.shared.passKeyManager(),
                               shareInviteRepository: self.inviteRepository,
                               userManager: self.userManager,
                               syncEventLoop: ServiceContainer.shared.syncEventLoop()) }
    }

    var promoteNewUserInvite: Factory<any PromoteNewUserInviteUseCase> {
        self { PromoteNewUserInvite(publicKeyRepository: self.publicKeyRepository,
                                    passKeyManager: RepositoryContainer.shared.passKeyManager(),
                                    shareInviteRepository: self.inviteRepository,
                                    userManager: self.userManager) }
    }

    var getEmailPublicKey: Factory<any GetEmailPublicKeyUseCase> {
        self { GetEmailPublicKey(publicKeyRepository: self.publicKeyRepository) }
    }

    var checkAddressesForInvite: Factory<any CheckAddressesForInviteUseCase> {
        self { CheckAddressesForInvite(userManager: self.userManager,
                                       accessRepository: self.accessRepository,
                                       organizationRepository: RepositoryContainer.shared
                                           .organizationRepository(),
                                       shareInviteRepository: self.inviteRepository) }
    }

    @MainActor
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

    @MainActor
    var canUserPerformActionOnVault: Factory<any CanUserPerformActionOnVaultUseCase> {
        self {
            CanUserPerformActionOnVault(accessRepository: self.accessRepository,
                                        appContentManager: self.appContentManager)
        }
    }
}

// MARK: - Invites

public extension UseCasesContainer {
    var getPendingUserInvitations: Factory<any GetPendingUserInvitationsUseCase> {
        self { GetPendingUserInvitations(repository: self.inviteRepository,
                                         userManager: self.userManager) }
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
        self { UpdateCachedInvitations(repository: self.inviteRepository,
                                       userManager: self.userManager) }
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

    @MainActor
    var canUserTransferVaultOwnership: Factory<any CanUserTransferVaultOwnershipUseCase> {
        self { CanUserTransferVaultOwnership(appContentManager: self.appContentManager) }
    }

    var makeUnsignedSignatureForVaultSharing: Factory<any MakeUnsignedSignatureForVaultSharingUseCase> {
        self { MakeUnsignedSignatureForVaultSharing() }
    }

    var getInviteDecryptionKeys: Factory<any GetInviteDecryptionKeysUseCase> {
        self { GetInviteDecryptionKeys(userManager: self.userManager,
                                       groupRepository: RepositoryContainer.shared.groupRepository(),
                                       decryptGroupKeys: self.decryptGroupKey(),
                                       updateUserAddresses: self.updateUserAddresses()) }
    }
}

// MARK: - Vaults

public extension UseCasesContainer {
    @MainActor
    var getVaultItemCount: Factory<any GetVaultItemCountUseCase> {
        self { GetVaultItemCount(appContentManager: self.appContentManager) }
    }

    var transferVaultOwnership: Factory<any TransferVaultOwnershipUseCase> {
        self { TransferVaultOwnership(repository: self.shareRepository) }
    }

    @MainActor
    var moveItemsBetweenContainers: Factory<any MoveItemsBetweenContainersUseCase> {
        self {
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

    @MainActor
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

public extension UseCasesContainer {
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

public extension UseCasesContainer {
    var getAllPinnedItems: Factory<any GetAllPinnedItemsUseCase> {
        self { GetAllPinnedItems(itemRepository: self.itemRepository) }
    }

    @MainActor
    var getSearchableItems: Factory<any GetSearchableItemsUseCase> {
        self { GetSearchableItems(itemRepository: self.itemRepository,
                                  shareRepository: self.shareRepository,
                                  getAllPinnedItems: self.getAllPinnedItems(),
                                  dedupShare: self.dedupShare(),
                                  symmetricKeyProvider: self.symmetricKeyProvider,
                                  appContentManager: self.appContentManager,
                                  logManager: self.logManager) }
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

public extension UseCasesContainer {
    var updateUserAddresses: Factory<any UpdateUserAddressesUseCase> {
        self { UpdateUserAddresses(userManager: self.userManager,
                                   apiServicing: self.apiManager) }
    }

    var refreshAccessAndMonitorState: Factory<any RefreshAccessAndMonitorStateUseCase> {
        self { RefreshAccessAndMonitorState(accessRepository: self.accessRepository,
                                            passMonitorRepository: self.passMonitorRepository,
                                            getAllAliases: self.getAllAliases(),
                                            getBreachesForAlias: self.getBreachesForAlias(),
                                            stream: DataContainer.shared.monitorStateStream()) }
    }

    var verifyProtonPassword: Factory<any VerifyProtonPasswordUseCase> {
        self { VerifyProtonPassword(userManager: self.userManager,
                                    doh: ToolingContainer.shared.doh(),
                                    appVer: ToolingContainer.shared.appVersion()) }
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
                                remoteDatasource: RepositoryContainer.shared.remoteAccessDatasource(),
                                authManager: ToolingContainer.shared.authManager()) }
    }

    @MainActor
    var logOutExcessFreeAccounts: Factory<any LogOutExcessFreeAccountsUseCase> {
        self { LogOutExcessFreeAccounts(datasource: self.localAccessDatasource,
                                        logOutUser: self.logOutUser()) }
    }

    // periphery:ignore
    var checkFlagForMultiUsers: Factory<any CheckFlagForMultiUsersUseCase> {
        self { CheckFlagForMultiUsers(apiServicing: self.apiManager) }
    }
}

// MARK: - Misc

public extension UseCasesContainer {
    var getRustLibraryVersion: Factory<any GetRustLibraryVersionUseCase> {
        self { GetRustLibraryVersion() }
    }

    var enableAutoFill: Factory<any EnableAutoFillUseCase> {
        self { EnableAutoFill(credentialManager: ServiceContainer.shared.credentialManager()) }
    }

    var makeAccountSettingsUrl: Factory<any MakeAccountSettingsUrlUseCase> {
        self { MakeAccountSettingsUrl(doh: ToolingContainer.shared.doh()) }
    }
}

// MARK: - App

public extension UseCasesContainer {
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

    var setUpAppearances: Factory<any SetUpAppearancesUseCase> {
        self { SetUpAppearances() }
    }
}

// MARK: - Security

public extension UseCasesContainer {
    var getAllSecurityAffectedLogins: Factory<any GetAllSecurityAffectedLoginsUseCase> {
        self {
            GetAllSecurityAffectedLogins(passMonitorRepository: self.passMonitorRepository,
                                         symmetricKeyProvider: DataContainer.shared
                                             .nonSendableSymmetricKeyProvider(),
                                         getPasswordStrength: self.getPasswordStrength())
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
        self { GetAllAliasMonitorInfos(getAllAliasesUseCase: self.getAllAliases(),
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

public extension UseCasesContainer {
    var overrideSecuritySettings: Factory<any OverrideSecuritySettingsUseCase> {
        self { OverrideSecuritySettings(preferencesManager: ToolingContainer.shared.preferencesManager()) }
    }

    var addItemReadEvent: Factory<any AddItemReadEventUseCase> {
        self { AddItemReadEvent(eventRepository: RepositoryContainer.shared.itemReadEventRepository(),
                                accessRepository: self.accessRepository,
                                userManager: self.userManager,
                                logManager: self.logManager) }
    }

    var resolvePasswordPolicy: Factory<any ResolvePasswordPolicyUseCase> {
        self { ResolvePasswordPolicy() }
    }
}

// MARK: - Secure link

public extension UseCasesContainer {
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

// MARK: Computed properties

private extension UseCasesContainer {
    var preferencesManager: any PreferencesManagerProtocol {
        ToolingContainer.shared.preferencesManager()
    }

    var credentialManager: any CredentialManagerProtocol {
        ServiceContainer.shared.credentialManager()
    }

    var userSettingsRepository: any UserSettingsRepositoryProtocol {
        RepositoryContainer.shared.userSettingsRepository()
    }

    var authManager: any AuthManagerProtocol {
        ToolingContainer.shared.authManager()
    }

    var syncEventLoop: any SyncEventLoopProtocol {
        ServiceContainer.shared.syncEventLoop()
    }

    var keychain: any KeychainProtocol {
        ToolingContainer.shared.keychain()
    }

    var organizationRepository: any OrganizationRepositoryProtocol {
        RepositoryContainer.shared.organizationRepository()
    }
}

// MARK: App

public extension UseCasesContainer {
    var setUpBeforeLaunching: Factory<any SetUpBeforeLaunchingUseCase> {
        self { SetUpBeforeLaunching(keychain: self.keychain,
                                    databaseService: ServiceContainer.shared.databaseService(),
                                    symmetricKeyProvider: self.symmetricKeyProvider,
                                    userManager: self.userManager,
                                    prefererencesManager: self.preferencesManager,
                                    authManager: DataContainer.shared.credentialProvider(),
                                    applyMigration: self.applyAppMigration(),
                                    setUpAppearances: self.setUpAppearances()) }
    }
}

// MARK: Permission

public extension UseCasesContainer {
    var checkCameraPermission: Factory<any CheckCameraPermissionUseCase> {
        self { CheckCameraPermission() }
    }
}

// MARK: Local authentication

public extension UseCasesContainer {
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

public extension UseCasesContainer {
    var addTelemetryEvent: Factory<any AddTelemetryEventUseCase> {
        self { AddTelemetryEvent(repository: RepositoryContainer.shared.telemetryEventRepository(),
                                 userManager: self.userManager,
                                 logManager: self.logManager) }
    }

    // periphery:ignore
    var sendTelemetryEvent: Factory<any SendTelemetryEventUseCase> {
        self {
            SendTelemetryEvent(datasource: RepositoryContainer.shared.remoteTelemetryEventDatasource(),
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
        self { SetUpCoreTelemetry(telemetryService: ServiceContainer.shared.telemetryService(),
                                  apiServicing: ToolingContainer.shared.apiManager(),
                                  logManager: self.logManager,
                                  userSettingsRepository: self.userSettingsRepository,
                                  userManager: self.userManager) }
    }
}

// MARK: AutoFill

public extension UseCasesContainer {
    var mapLoginItem: Factory<any MapLoginItemUseCase> {
        self { MapLoginItem() }
    }

    var indexAllLoginItems: Factory<any IndexAllLoginItemsUseCase> {
        self { IndexAllLoginItems(userManager: self.userManager,
                                  itemRepository: self.itemRepository,
                                  shareRepository: self.shareRepository,
                                  localAccessDatasource: RepositoryContainer.shared.localAccessDatasource(),
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

public extension UseCasesContainer {
    var indexItemsForSpotlight: Factory<any IndexItemsForSpotlightUseCase> {
        self { IndexItemsForSpotlight(userManager: self.userManager,
                                      itemRepository: self.itemRepository,
                                      datasource: RepositoryContainer.shared
                                          .localSpotlightVaultDatasource(),
                                      logManager: self.logManager) }
    }
}

// MARK: Vault

public extension UseCasesContainer {
    var processVaultSyncEvent: Factory<any ProcessVaultSyncEventUseCase> {
        self { ProcessVaultSyncEvent() }
    }

    @MainActor
    var getMainVault: Factory<any GetMainVaultUseCase> {
        self { GetMainVault(appContentManager: self.appContentManager) }
    }

    @MainActor
    var fullContentSync: Factory<any FullContentSyncUseCase> {
        self { FullContentSync(syncEventLoop: ServiceContainer.shared.syncEventLoop(),
                               appContentManager: self.appContentManager) }
    }
}

// MARK: - Folders

public extension UseCasesContainer {
    var userHasRemoteFolders: Factory<any UserHasRemoteFoldersUseCase> {
        self { UserHasRemoteFolders(shareRepository: RepositoryContainer.shared.shareRepository(),
                                    remoteFolderDatasource: RepositoryContainer.shared
                                        .remoteFolderDatasource()) }
    }

    var shouldShowFolderSyncBanner: Factory<any ShouldShowFolderSyncBannerUseCase> {
        self { ShouldShowFolderSyncBanner(getUserPreferences: self.getUserPreferences(),
                                          getFeatureFlagStatus: self.getFeatureFlagStatus(),
                                          userHasRemoteFolders: self.userHasRemoteFolders(),
                                          userManager: self.userManager,
                                          storage: kSharedUserDefaults,
                                          logManager: self.logManager) }
    }

    var shouldForceSyncForFolders: Factory<any ShouldForceSyncForFoldersUseCase> {
        self { ShouldForceSyncForFolders(getUserPreferences: self.getUserPreferences(),
                                         getFeatureFlagStatus: self.getFeatureFlagStatus(),
                                         refreshFeatureFlags: self.refreshFeatureFlags(),
                                         userHasRemoteFolders: self.userHasRemoteFolders(),
                                         updateUserPreferences: self.updateUserPreferences(),
                                         reachability: ServiceContainer.shared
                                             .reachabilityService()) }
    }
}

// MARK: - Feature Flags

public extension UseCasesContainer {
    var getFeatureFlagStatus: Factory<any GetFeatureFlagStatusUseCase> {
        self {
            GetFeatureFlagStatus(repository: RepositoryContainer.shared.featureFlagsRepository())
        }
    }
}

// MARK: TOTP

public extension UseCasesContainer {
    var sanitizeTotpUriForEditing: Factory<any SanitizeTotpUriForEditingUseCase> {
        self { SanitizeTotpUriForEditing() }
    }

    var sanitizeTotpUriForSaving: Factory<any SanitizeTotpUriForSavingUseCase> {
        self { SanitizeTotpUriForSaving() }
    }

    var generateTotpToken: Factory<any GenerateTotpTokenUseCase> {
        self { GenerateTotpToken(totpService: ServiceContainer.shared.totpService()) }
    }
}

// MARK: Rust Utils

public extension UseCasesContainer {
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

    var scorePassword: Factory<any ScorePasswordUseCase> {
        self { ScorePassword() }
    }

    var generateUsername: Factory<any GenerateUsernameUseCase> {
        self { GenerateUsername() }
    }
}

// MARK: Data

public extension UseCasesContainer {
    var revokeCurrentSession: Factory<any RevokeCurrentSessionUseCase> {
        self { RevokeCurrentSession(networkRepository: RepositoryContainer.shared.networkRepository(),
                                    userManager: self.userManager) }
    }

    var deleteLocalDataBeforeFullSync: Factory<any DeleteLocalDataBeforeFullSyncUseCase> {
        self { DeleteLocalDataBeforeFullSync(itemRepository: self.itemRepository,
                                             shareRepository: self.shareRepository,
                                             shareKeyRepository: RepositoryContainer.shared
                                                 .shareKeyRepository(),
                                             folderKeyDatasource: RepositoryContainer.shared
                                                 .localFolderKeyDatasource(),
                                             folderRepository: RepositoryContainer.shared
                                                 .folderRepository()) }
    }

    @MainActor
    var logOutUser: Factory<any LogOutUserUseCase> {
        self {
            LogOutUser(userManager: self.userManager,
                       syncEventLoop: ServiceContainer.shared.syncEventLoop(),
                       preferencesManager: self.preferencesManager,
                       removeUserLocalData: self.removeUserLocalData(),
                       featureFlagsRepository: RepositoryContainer.shared.featureFlagsRepository(),
                       passMonitorRepository: self.passMonitorRepository,
                       accessRepository: self.accessRepository,
                       appContentManager: self.appContentManager,
                       apiManager: self.apiManager,
                       authManager: self.authManager,
                       credentialManager: ServiceContainer.shared.credentialManager(),
                       switchUser: self.switchUser())
        }
    }

    var getUserUiModels: Factory<any GetUserUiModelsUseCase> {
        self { GetUserUiModels(userManager: self.userManager,
                               localAccessDatasource: RepositoryContainer.shared.localAccessDatasource()) }
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

public extension UseCasesContainer {
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
        self { GetActiveLoginItems(symmetricKeyProvider: DataContainer.shared.symmetricKeyProvider(),
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

public extension UseCasesContainer {
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

public extension UseCasesContainer {
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
            let container = RepositoryContainer.shared
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
                                 featureFlagsRepository: RepositoryContainer.shared.featureFlagsRepository(),
                                 passMonitorRepository: self.passMonitorRepository,
                                 appContentManager: self.appContentManager,
                                 apiManager: self.apiManager,
                                 authManager: self.authManager,
                                 credentialManager: ServiceContainer.shared.credentialManager(),
                                 keychain: self.keychain) }
    }

    var getLastEventIdIfNotExist: Factory<any GetLastEventIdIfNotExistUseCase> {
        self {
            let container = RepositoryContainer.shared
            return GetLastEventIdIfNotExist(localDatasource: container.localUserEventIdDatasource(),
                                            remoteDatasource: container.remoteUserEventsDatasource())
        }
    }

    var refreshUserData: Factory<any RefreshUserDataUseCase> {
        self { RefreshUserData(remoteDatasource: RepositoryContainer.shared.remoteUserDataDatasource(),
                               userManager: self.userManager) }
    }
}

// MARK: Passkey

public extension UseCasesContainer {
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

public extension UseCasesContainer {
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

public extension UseCasesContainer {
    var copyToClipboard: Factory<any CopyToClipboardUseCase> {
        self { CopyToClipboard(getSharedPreferences: self.getSharedPreferences()) }
    }

    var applyAppMigration: Factory<any ApplyAppMigrationUseCase> {
        self { ApplyAppMigration(dataMigrationManager: ServiceContainer.shared.dataMigrationManager(),
                                 userManager: self.userManager,
                                 authManager: self.authManager,
                                 itemDatasource: RepositoryContainer.shared.localItemDatasource(),
                                 searchEntryDatasource: RepositoryContainer.shared
                                     .localSearchEntryDatasource(),
                                 shareKeyDatasource: RepositoryContainer.shared.localShareKeyDatasource(),
                                 logManager: self.logManager) }
    }
}

// MARK: - Dark web monitor

public extension UseCasesContainer {
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

public extension UseCasesContainer {
    var refreshFeatureFlags: Factory<any RefreshFeatureFlagsUseCase> {
        self { RefreshFeatureFlags(repository: RepositoryContainer.shared.featureFlagsRepository(),
                                   apiServicing: self.apiManager,
                                   userManager: self.userManager,
                                   logManager: self.logManager) }
    }
}

// MARK: - File attachments

public extension UseCasesContainer {
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
                                      keyManager: RepositoryContainer.shared.passKeyManager(),
                                      apiService: ToolingContainer.shared.apiServiceLite()) }
    }

    var getFilesToLink: Factory<any GetFilesToLinkUseCase> {
        self { GetFilesToLink() }
    }

    var clearCacheForLoggedOutUsers: Factory<any ClearCacheForLoggedOutUsersUseCase> {
        self {
            ClearCacheForLoggedOutUsers(datasource: RepositoryContainer.shared.localUserDataDatasource())
        }
    }

    var sanitizeFileName: Factory<any SanitizeFileNameUseCase> {
        self { SanitizeFileName() }
    }
}
