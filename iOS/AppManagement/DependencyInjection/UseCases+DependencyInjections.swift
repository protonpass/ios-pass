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

import Core
import Factory
import ProtonCore_Services

final class UseCasesContainer: SharedContainer, AutoRegistering {
    static let shared = UseCasesContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .shared
    }
}

// MARK: - Computed properties

private extension UseCasesContainer {
    var apiService: APIService {
        SharedToolingContainer.shared.apiManager().apiService
    }

    var logManager: LogManagerProtocol {
        SharedToolingContainer.shared.logManager()
    }
}

// MARK: User report

extension UseCasesContainer {
    var sendUserBugReport: Factory<SendUserBugReportUseCase> {
        self { SendUserBugReport(reportRepository: RepositoryContainer.shared.reportRepository(),
                                 extractLogsToFile: self.extractLogsToFile(),
                                 getLogEntries: self.getLogEntries()) }
    }

    var sendUserFeedBack: Factory<SendUserFeedBackUseCase> {
        self { SendUserFeedBack(reportRepository: RepositoryContainer.shared.reportRepository()) }
    }
}

// MARK: Logs

extension UseCasesContainer {
    var extractLogsToFile: Factory<ExtractLogsToFileUseCase> {
        self { ExtractLogsToFile(logFormatter: SharedToolingContainer.shared.logFormatter()) }
    }

    var extractLogsToData: Factory<ExtractLogsToDataUseCase> {
        self { ExtractLogsToData(logFormatter: SharedToolingContainer.shared.logFormatter()) }
    }

    var getLogEntries: Factory<GetLogEntriesUseCase> {
        self { GetLogEntries(mainAppLogManager: SharedToolingContainer.shared.specificLogManager(.hostApp),
                             autofillLogManager: SharedToolingContainer.shared
                                 .specificLogManager(.autoFillExtension),
                             keyboardLogManager: SharedToolingContainer.shared
                                 .specificLogManager(.keyboardExtension)) }
    }
}

// MARK: - Sharing

extension UseCasesContainer {
    var getCurrentShareInviteInformations: Factory<GetCurrentShareInviteInformationsUseCase> {
        self { GetCurrentShareInviteInformations(shareInviteService: ServiceContainer.shared.shareInviteService())
        }
    }

    var setShareInviteVault: Factory<SetShareInviteVaultUseCase> {
        self { SetShareInviteVault(shareInviteService: ServiceContainer.shared.shareInviteService(),
                                   getVaultItemCount: self.getVaultItemCount()) }
    }

    var setShareInviteUserEmailAndKeys: Factory<SetShareInviteUserEmailAndKeysUseCase> {
        self { SetShareInviteUserEmailAndKeys(shareInviteService: ServiceContainer.shared.shareInviteService()) }
    }

    var setShareInviteRole: Factory<SetShareInviteRoleUseCase> {
        self { SetShareInviteRole(shareInviteService: ServiceContainer.shared.shareInviteService()) }
    }

    var sendVaultShareInvite: Factory<SendVaultShareInviteUseCase> {
        self { SendVaultShareInvite(passKeyManager: SharedRepositoryContainer.shared.passKeyManager(),
                                    shareInviteRepository: SharedRepositoryContainer.shared
                                        .shareInviteRepository(),
                                    userData: SharedDataContainer.shared.userData()) }
    }

    var getEmailPublicKey: Factory<GetEmailPublicKeyUseCase> {
        self { GetEmailPublicKey(publicKeyRepository: SharedRepositoryContainer.shared.publicKeyRepository()) }
    }

    var leaveShare: Factory<LeaveShareUseCase> {
        self { LeaveShare(repository: SharedRepositoryContainer.shared.shareRepository()) }
    }

    var getUsersLinkedToShare: Factory<GetUsersLinkedToShareUseCase> {
        self { GetUsersLinkedToShare(repository: SharedRepositoryContainer.shared.shareRepository()) }
    }

    var getPendingInvitationsForShare: Factory<GetPendingInvitationsForShareUseCase> {
        self { GetPendingInvitationsForShare(repository: SharedRepositoryContainer.shared.shareInviteRepository())
        }
    }

    var getAllUsersForShare: Factory<GetAllUsersForShareUseCase> {
        self { GetAllUsersForShare(getUsersLinkedToShare: self.getUsersLinkedToShare(),
                                   getPendingInvitationsForShare: self.getPendingInvitationsForShare()) }
    }

    var updateUserShareRole: Factory<UpdateUserShareRoleUseCase> {
        self { UpdateUserShareRole(repository: SharedRepositoryContainer.shared.shareRepository()) }
    }
}

// MARK: - Invites

extension UseCasesContainer {
    var getPendingUserInvitations: Factory<GetPendingUserInvitationsUseCase> {
        self { GetPendingUserInvitations(repository: RepositoryContainer.shared.inviteRepository()) }
    }

    var refreshInvitations: Factory<RefreshInvitationsUseCase> {
        self { RefreshInvitations(repository: RepositoryContainer.shared.inviteRepository(),
                                  getFeatureFlagStatus: self.getFeatureFlagStatus()) }
    }

    var rejectInvitation: Factory<RejectInvitationUseCase> {
        self { RejectInvitation(repository: RepositoryContainer.shared.inviteRepository()) }
    }

    var acceptInvitation: Factory<AcceptInvitationUseCase> {
        self { AcceptInvitation(repository: RepositoryContainer.shared.inviteRepository(),
                                userData: SharedDataContainer.shared.userData(),
                                getEmailPublicKey: self.getEmailPublicKey()) }
    }

    var decodeShareVaultInformation: Factory<DecodeShareVaultInformationUseCase> {
        self { DecodeShareVaultInformation(userData: SharedDataContainer.shared.userData(),
                                           getEmailPublicKey: self.getEmailPublicKey()) }
    }

    var updateCachedInvitations: Factory<UpdateCachedInvitationsUseCase> {
        self { UpdateCachedInvitations(repository: RepositoryContainer.shared.inviteRepository()) }
    }

    var revokeInvitation: Factory<RevokeInvitationUseCase> {
        self { RevokeInvitation(shareInviteRepository: SharedRepositoryContainer.shared.shareInviteRepository()) }
    }

    var sendInviteReminder: Factory<SendInviteReminderUseCase> {
        self { SendInviteReminder(shareInviteRepository: SharedRepositoryContainer.shared.shareInviteRepository())
        }
    }
}

// MARK: - Flags

extension UseCasesContainer {
    var userSharingStatus: Factory<UserSharingStatusUseCase> {
        self { UserSharingStatus(getFeatureFlagStatus: self.getFeatureFlagStatus(),
                                 passPlanRepository: SharedRepositoryContainer.shared.passPlanRepository(),
                                 logManager: SharedToolingContainer.shared.logManager()) }
    }

    var getFeatureFlagStatus: Factory<GetFeatureFlagStatusUseCase> {
        self {
            GetFeatureFlagStatus(featureFlagsRepository: SharedRepositoryContainer.shared.featureFlagsRepository(),
                                 logManager: SharedToolingContainer.shared.logManager())
        }
    }
}

// MARK: - Vaults

extension UseCasesContainer {
    var getVaultItemCount: Factory<GetVaultItemCountUseCase> {
        self { GetVaultItemCount(vaultsManager: SharedServiceContainer.shared.vaultsManager()) }
    }
}

// MARK: - User

extension UseCasesContainer {
    var checkAccessToPass: Factory<CheckAccessToPassUseCase> {
        self { CheckAccessToPass(apiService: self.apiService, logManager: self.logManager) }
    }

    var refreshFeatureFlags: Factory<RefreshFeatureFlagsUseCase> {
        self { RefreshFeatureFlags(repository: SharedRepositoryContainer.shared.featureFlagsRepository(),
                                   logManager: self.logManager) }
    }
}
