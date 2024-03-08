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
import ProtonCoreServices
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
    var logManager: LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }

    var shareInviteService: ShareInviteServiceProtocol {
        ServiceContainer.shared.shareInviteService()
    }

    var userDataProvider: UserDataProvider {
        SharedDataContainer.shared.userDataProvider()
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
        RepositoryContainer.shared.inviteRepository()
    }

    var publicKeyRepository: any PublicKeyRepositoryProtocol {
        SharedRepositoryContainer.shared.publicKeyRepository()
    }

    var vaultsManager: any VaultsManagerProtocol {
        SharedServiceContainer.shared.vaultsManager()
    }
}

// MARK: User report

extension UseCasesContainer {
    var sendUserBugReport: Factory<SendUserBugReportUseCase> {
        self { SendUserBugReport(reportRepository: RepositoryContainer.shared.reportRepository(),
                                 extractLogsToFile: self.extractLogsToFile(),
                                 getLogEntries: self.getLogEntries()) }
    }
}

// MARK: Logs

extension UseCasesContainer {
    var extractLogsToFile: Factory<ExtractLogsToFileUseCase> {
        self { ExtractLogsToFile(logFormatter: SharedToolingContainer.shared.logFormatter()) }
    }

    var getLogEntries: Factory<GetLogEntriesUseCase> {
        self { GetLogEntries(mainAppLogManager: SharedToolingContainer.shared.specificLogManager(.hostApp),
                             autofillLogManager: SharedToolingContainer.shared
                                 .specificLogManager(.autoFillExtension),
                             keyboardLogManager: SharedToolingContainer.shared
                                 .specificLogManager(.keyboardExtension),
                             shareLogManager: SharedToolingContainer.shared
                                 .specificLogManager(.shareExtension)) }
    }
}

// MARK: - Sharing

extension UseCasesContainer {
    var createAndMoveItemToNewVault: Factory<CreateAndMoveItemToNewVaultUseCase> {
        self { CreateAndMoveItemToNewVault(createVault: self.createVault(),
                                           moveItemsBetweenVaults: self.moveItemsBetweenVaults(),
                                           vaultsManager: self.vaultsManager) }
    }

    var getCurrentShareInviteInformations: Factory<GetCurrentShareInviteInformationsUseCase> {
        self { GetCurrentShareInviteInformations(shareInviteService: self.shareInviteService)
        }
    }

    var setShareInviteVault: Factory<SetShareInviteVaultUseCase> {
        self { SetShareInviteVault(shareInviteService: self.shareInviteService,
                                   getVaultItemCount: self.getVaultItemCount()) }
    }

    var setShareInvitesUserEmailsAndKeys: Factory<SetShareInvitesUserEmailsAndKeysUseCase> {
        self { SetShareInvitesUserEmailsAndKeys(shareInviteService: self.shareInviteService,
                                                getEmailPublicKeyUseCase: self.getEmailPublicKey()) }
    }

    var setShareInviteRole: Factory<SetShareInviteRoleUseCase> {
        self { SetShareInviteRole(shareInviteService: self.shareInviteService) }
    }

    var sendVaultShareInvite: Factory<SendVaultShareInviteUseCase> {
        self { SendVaultShareInvite(createAndMoveItemToNewVault: self.createAndMoveItemToNewVault(),
                                    makeUnsignedSignatureForVaultSharing: self
                                        .makeUnsignedSignatureForVaultSharing(),
                                    shareInviteService: self.shareInviteService,
                                    passKeyManager: SharedRepositoryContainer.shared.passKeyManager(),
                                    shareInviteRepository: self.shareInviteRepository,
                                    userDataProvider: self.userDataProvider,
                                    syncEventLoop: SharedServiceContainer.shared.syncEventLoop()) }
    }

    var promoteNewUserInvite: Factory<PromoteNewUserInviteUseCase> {
        self { PromoteNewUserInvite(publicKeyRepository: self.publicKeyRepository,
                                    passKeyManager: SharedRepositoryContainer.shared.passKeyManager(),
                                    shareInviteRepository: self.shareInviteRepository,
                                    userDataProvider: self.userDataProvider) }
    }

    var getEmailPublicKey: Factory<GetEmailPublicKeyUseCase> {
        self { GetEmailPublicKey(publicKeyRepository: self.publicKeyRepository) }
    }

    var leaveShare: Factory<LeaveShareUseCase> {
        self { LeaveShare(vaultManager: self.vaultsManager) }
    }

    var getUsersLinkedToShare: Factory<GetUsersLinkedToShareUseCase> {
        self { GetUsersLinkedToShare(repository: self.shareRepository) }
    }

    var getPendingInvitationsForShare: Factory<GetPendingInvitationsForShareUseCase> {
        self { GetPendingInvitationsForShare(repository: self.shareInviteRepository) }
    }

    var updateUserShareRole: Factory<UpdateUserShareRoleUseCase> {
        self { UpdateUserShareRole(repository: self.shareRepository) }
    }

    var revokeUserShareAccess: Factory<RevokeUserShareAccessUseCase> {
        self { RevokeUserShareAccess(repository: self.shareRepository) }
    }

    var getUserShareStatus: Factory<GetUserShareStatusUseCase> {
        self {
            GetUserShareStatus(accessRepository: self.accessRepository)
        }
    }

    var canUserPerformActionOnVault: Factory<CanUserPerformActionOnVaultUseCase> {
        self {
            CanUserPerformActionOnVault(accessRepository: self.accessRepository,
                                        vaultsManager: self.vaultsManager)
        }
    }
}

// MARK: - Invites

extension UseCasesContainer {
    var getPendingUserInvitations: Factory<GetPendingUserInvitationsUseCase> {
        self { GetPendingUserInvitations(repository: self.inviteRepository) }
    }

    var refreshInvitations: Factory<RefreshInvitationsUseCase> {
        self { RefreshInvitations(inviteRepository: self.inviteRepository,
                                  accessRepository: self.accessRepository) }
    }

    var rejectInvitation: Factory<RejectInvitationUseCase> {
        self { RejectInvitation(repository: self.inviteRepository) }
    }

    var acceptInvitation: Factory<AcceptInvitationUseCase> {
        self { AcceptInvitation(repository: self.inviteRepository,
                                userDataProvider: self.userDataProvider,
                                getEmailPublicKey: self.getEmailPublicKey(),
                                updateUserAddresses: self.updateUserAddresses(),
                                logManager: self.logManager) }
    }

    var decodeShareVaultInformation: Factory<DecodeShareVaultInformationUseCase> {
        self { DecodeShareVaultInformation(userDataProvider: self.userDataProvider,
                                           getEmailPublicKey: self.getEmailPublicKey(),
                                           updateUserAddresses: self.updateUserAddresses(),
                                           logManager: self.logManager) }
    }

    var updateCachedInvitations: Factory<UpdateCachedInvitationsUseCase> {
        self { UpdateCachedInvitations(repository: self.inviteRepository) }
    }

    var revokeInvitation: Factory<RevokeInvitationUseCase> {
        self { RevokeInvitation(shareInviteRepository: self.shareInviteRepository) }
    }

    var revokeNewUserInvitation: Factory<RevokeNewUserInvitationUseCase> {
        self {
            RevokeNewUserInvitation(shareInviteRepository: self.shareInviteRepository)
        }
    }

    var sendInviteReminder: Factory<SendInviteReminderUseCase> {
        self { SendInviteReminder(shareInviteRepository: self.shareInviteRepository)
        }
    }

    var canUserTransferVaultOwnership: Factory<CanUserTransferVaultOwnershipUseCase> {
        self { CanUserTransferVaultOwnership(vaultsManager: self.vaultsManager) }
    }

    var makeUnsignedSignatureForVaultSharing: Factory<MakeUnsignedSignatureForVaultSharingUseCase> {
        self { MakeUnsignedSignatureForVaultSharing() }
    }
}

// MARK: - Flags

extension UseCasesContainer {
    var refreshFeatureFlags: Factory<RefreshFeatureFlagsUseCase> {
        self { RefreshFeatureFlags(repository: SharedRepositoryContainer.shared.featureFlagsRepository(),
                                   userDataProvider: self.userDataProvider,
                                   logManager: self.logManager) }
    }
}

// MARK: - Vaults

extension UseCasesContainer {
    var getVaultItemCount: Factory<GetVaultItemCountUseCase> {
        self { GetVaultItemCount(vaultsManager: self.vaultsManager) }
    }

    var transferVaultOwnership: Factory<TransferVaultOwnershipUseCase> {
        self { TransferVaultOwnership(repository: self.shareRepository) }
    }

    var moveItemsBetweenVaults: Factory<MoveItemsBetweenVaultsUseCase> {
        self { MoveItemsBetweenVaults(repository: self.itemRepository) }
    }

    var trashSelectedItems: Factory<TrashSelectedItemsUseCase> {
        self { TrashSelectedItems(repository: self.itemRepository) }
    }

    var restoreSelectedItems: Factory<RestoreSelectedItemsUseCase> {
        self { RestoreSelectedItems(repository: self.itemRepository) }
    }

    var permanentlyDeleteSelectedItems: Factory<PermanentlyDeleteSelectedItemsUseCase> {
        self { PermanentlyDeleteSelectedItems(repository: self.itemRepository) }
    }

    var getVaultContentForVault: Factory<GetVaultContentForVaultUseCase> {
        self { GetVaultContentForVault(vaultsManager: self.vaultsManager) }
    }

    var createVault: Factory<CreateVaultUseCase> {
        self { CreateVault(vaultsManager: self.vaultsManager,
                           repository: self.shareRepository) }
    }

    var reachedVaultLimit: Factory<ReachedVaultLimitUseCase> {
        self { ReachedVaultLimit(accessRepository: self.accessRepository,
                                 vaultsManager: self.vaultsManager) }
    }
}

// MARK: Spotlight

extension UseCasesContainer {
    var getSpotlightVaults: Factory<GetSpotlightVaultsUseCase> {
        self { GetSpotlightVaults(userDataProvider: self.userDataProvider,
                                  shareRepository: self.shareRepository,
                                  localSpotlightVaultDatasource: self
                                      .localSpotlightVaultDatasource) }
    }

    var updateSpotlightVaults: Factory<UpdateSpotlightVaultsUseCase> {
        self { UpdateSpotlightVaults(userDataProvider: self.userDataProvider,
                                     datasource: self.localSpotlightVaultDatasource) }
    }
}

// MARK: - items

extension UseCasesContainer {
    var getAllPinnedItems: Factory<GetAllPinnedItemsUseCase> {
        self { GetAllPinnedItems(itemRepository: self.itemRepository) }
    }

    var getSearchableItems: Factory<GetSearchableItemsUseCase> {
        self { GetSearchableItems(itemRepository: self.itemRepository,
                                  shareRepository: self.shareRepository,
                                  getAllPinnedItems: self.getAllPinnedItems(),
                                  symmetricKeyProvider: self.symmetricKeyProvider) }
    }

    var getItemHistory: Factory<GetItemHistoryUseCase> {
        self { GetItemHistory(itemRepository: self.itemRepository) }
    }

    var getItemContentFromBase64IDs: Factory<GetItemContentFromBase64IDsUseCase> {
        self { GetItemContentFromBase64IDs(itemRepository: self.itemRepository,
                                           symmetricKeyProvider: self.symmetricKeyProvider) }
    }
}

// MARK: - User

extension UseCasesContainer {
    var updateUserAddresses: Factory<UpdateUserAddressesUseCase> {
        self { UpdateUserAddresses(userDataProvider: self.userDataProvider,
                                   authenticator: ServiceContainer.shared.authenticator()) }
    }
}

// MARK: - Misc

extension UseCasesContainer {
    var getRustLibraryVersion: Factory<GetRustLibraryVersionUseCase> {
        self { GetRustLibraryVersion() }
    }

    @MainActor
    var openAutoFillSettings: Factory<OpenAutoFillSettingsUseCase> {
        self { OpenAutoFillSettings(router: SharedRouterContainer.shared.mainUIKitSwiftUIRouter()) }
    }

    var makeImportExportUrl: Factory<MakeImportExportUrlUseCase> {
        self { MakeImportExportUrl(doh: SharedToolingContainer.shared.doh()) }
    }

    var makeAccountSettingsUrl: Factory<MakeAccountSettingsUrlUseCase> {
        self { MakeAccountSettingsUrl(doh: SharedToolingContainer.shared.doh()) }
    }
}

// MARK: - App

extension UseCasesContainer {
    var shouldDisplayUpgradeAppBanner: Factory<ShouldDisplayUpgradeAppBannerUseCase> {
        self { ShouldDisplayUpgradeAppBanner(accessRepository: self.accessRepository,
                                             bundle: .main,
                                             userDefaults: .standard) }
    }
}
