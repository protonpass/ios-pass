//
// UseCases+DependencyInjections.swift
// Proton Pass - Created on 29/06/2023.
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
import Factory
import UseCases

final class UseCasesContainer: SharedContainer, AutoRegistering, Sendable {
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

    var shareInviteRepository: any ShareInviteRepositoryProtocol {
        SharedRepositoryContainer.shared.shareInviteRepository()
    }

    var inviteRepository: any InviteRepositoryProtocol {
        SharedRepositoryContainer.shared.inviteRepository()
    }

    var publicKeyRepository: any PublicKeyRepositoryProtocol {
        SharedRepositoryContainer.shared.publicKeyRepository()
    }

    var vaultsManager: any VaultsManagerProtocol {
        SharedServiceContainer.shared.vaultsManager()
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
        self { GetLogEntries(mainAppLogManager: SharedToolingContainer.shared.specificLogManager(.hostApp),
                             autofillLogManager: SharedToolingContainer.shared
                                 .specificLogManager(.autoFillExtension),
                             shareLogManager: SharedToolingContainer.shared
                                 .specificLogManager(.shareExtension)) }
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
                                           moveItemsBetweenVaults: self.moveItemsBetweenVaults(),
                                           vaultsManager: self.vaultsManager) }
    }

    var getCurrentShareInviteInformations: Factory<any GetCurrentShareInviteInformationsUseCase> {
        self { GetCurrentShareInviteInformations(shareInviteService: self.shareInviteService)
        }
    }

    var setShareInviteVault: Factory<any SetShareInviteVaultUseCase> {
        self { SetShareInviteVault(shareInviteService: self.shareInviteService,
                                   getVaultItemCount: self.getVaultItemCount()) }
    }

    var setShareInvitesUserEmailsAndKeys: Factory<any SetShareInvitesUserEmailsAndKeysUseCase> {
        self { SetShareInvitesUserEmailsAndKeys(shareInviteService: self.shareInviteService,
                                                getEmailPublicKeyUseCase: self.getEmailPublicKey()) }
    }

    var setShareInviteRole: Factory<any SetShareInviteRoleUseCase> {
        self { SetShareInviteRole(shareInviteService: self.shareInviteService) }
    }

    var sendVaultShareInvite: Factory<any SendVaultShareInviteUseCase> {
        self { SendVaultShareInvite(createAndMoveItemToNewVault: self.createAndMoveItemToNewVault(),
                                    makeUnsignedSignatureForVaultSharing: self
                                        .makeUnsignedSignatureForVaultSharing(),
                                    shareInviteService: self.shareInviteService,
                                    passKeyManager: SharedRepositoryContainer.shared.passKeyManager(),
                                    shareInviteRepository: self.shareInviteRepository,
                                    userManager: self.userManager,
                                    syncEventLoop: SharedServiceContainer.shared.syncEventLoop()) }
    }

    var promoteNewUserInvite: Factory<any PromoteNewUserInviteUseCase> {
        self { PromoteNewUserInvite(publicKeyRepository: self.publicKeyRepository,
                                    passKeyManager: SharedRepositoryContainer.shared.passKeyManager(),
                                    shareInviteRepository: self.shareInviteRepository,
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
                                       shareInviteRepository: self.shareInviteRepository) }
    }

    var leaveShare: Factory<any LeaveShareUseCase> {
        self { LeaveShare(vaultManager: self.vaultsManager) }
    }

    var getUsersLinkedToShare: Factory<any GetUsersLinkedToShareUseCase> {
        self { GetUsersLinkedToShare(repository: self.shareRepository) }
    }

    var getPendingInvitationsForShare: Factory<any GetPendingInvitationsForShareUseCase> {
        self { GetPendingInvitationsForShare(repository: self.shareInviteRepository) }
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
                                        vaultsManager: self.vaultsManager)
        }
    }
}

// MARK: - Invites

extension UseCasesContainer {
    var getPendingUserInvitations: Factory<any GetPendingUserInvitationsUseCase> {
        self { GetPendingUserInvitations(repository: self.inviteRepository) }
    }

    var refreshInvitations: Factory<any RefreshInvitationsUseCase> {
        self { RefreshInvitations(inviteRepository: self.inviteRepository) }
    }

    var rejectInvitation: Factory<any RejectInvitationUseCase> {
        self { RejectInvitation(repository: self.inviteRepository) }
    }

    var acceptInvitation: Factory<any AcceptInvitationUseCase> {
        self { AcceptInvitation(repository: self.inviteRepository,
                                userManager: self.userManager,
                                getEmailPublicKey: self.getEmailPublicKey(),
                                updateUserAddresses: self.updateUserAddresses(),
                                logManager: self.logManager) }
    }

    var decodeShareVaultInformation: Factory<any DecodeShareVaultInformationUseCase> {
        self { DecodeShareVaultInformation(userManager: self.userManager,
                                           getEmailPublicKey: self.getEmailPublicKey(),
                                           updateUserAddresses: self.updateUserAddresses(),
                                           logManager: self.logManager) }
    }

    var updateCachedInvitations: Factory<any UpdateCachedInvitationsUseCase> {
        self { UpdateCachedInvitations(repository: self.inviteRepository) }
    }

    var revokeInvitation: Factory<any RevokeInvitationUseCase> {
        self { RevokeInvitation(shareInviteRepository: self.shareInviteRepository) }
    }

    var revokeNewUserInvitation: Factory<any RevokeNewUserInvitationUseCase> {
        self {
            RevokeNewUserInvitation(shareInviteRepository: self.shareInviteRepository)
        }
    }

    var sendInviteReminder: Factory<any SendInviteReminderUseCase> {
        self { SendInviteReminder(shareInviteRepository: self.shareInviteRepository)
        }
    }

    var canUserTransferVaultOwnership: Factory<any CanUserTransferVaultOwnershipUseCase> {
        self { CanUserTransferVaultOwnership(vaultsManager: self.vaultsManager) }
    }

    var makeUnsignedSignatureForVaultSharing: Factory<any MakeUnsignedSignatureForVaultSharingUseCase> {
        self { MakeUnsignedSignatureForVaultSharing() }
    }
}

// MARK: - Vaults

extension UseCasesContainer {
    var getVaultItemCount: Factory<any GetVaultItemCountUseCase> {
        self { GetVaultItemCount(vaultsManager: self.vaultsManager) }
    }

    var transferVaultOwnership: Factory<any TransferVaultOwnershipUseCase> {
        self { TransferVaultOwnership(repository: self.shareRepository) }
    }

    var moveItemsBetweenVaults: Factory<any MoveItemsBetweenVaultsUseCase> {
        self { MoveItemsBetweenVaults(repository: self.itemRepository) }
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

    var getVaultContentForVault: Factory<any GetVaultContentForVaultUseCase> {
        self { GetVaultContentForVault(vaultsManager: self.vaultsManager) }
    }

    var createVault: Factory<any CreateVaultUseCase> {
        self { CreateVault(vaultsManager: self.vaultsManager,
                           repository: self.shareRepository) }
    }

    var reachedVaultLimit: Factory<any ReachedVaultLimitUseCase> {
        self { ReachedVaultLimit(accessRepository: self.accessRepository,
                                 vaultsManager: self.vaultsManager) }
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
                                  symmetricKeyProvider: self.symmetricKeyProvider) }
    }

    var getItemHistory: Factory<any GetItemHistoryUseCase> {
        self { GetItemHistory(itemRepository: self.itemRepository) }
    }

    var getItemContentFromBase64IDs: Factory<any GetItemContentFromBase64IDsUseCase> {
        self { GetItemContentFromBase64IDs(itemRepository: self.itemRepository,
                                           symmetricKeyProvider: self.symmetricKeyProvider) }
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

    var checkFlagForMultiUsers: Factory<any CheckFlagForMultiUsersUseCase> {
        self { CheckFlagForMultiUsers(apiServicing: self.apiManager) }
    }
}

// MARK: - Misc

extension UseCasesContainer {
    var getRustLibraryVersion: Factory<any GetRustLibraryVersionUseCase> {
        self { GetRustLibraryVersion() }
    }

    var openAutoFillSettings: Factory<any OpenAutoFillSettingsUseCase> {
        self { OpenAutoFillSettings(router: SharedRouterContainer.shared.mainUIKitSwiftUIRouter()) }
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
