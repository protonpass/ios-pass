//
//
// ManageSharedShareViewModel.swift
// Proton Pass - Created on 02/08/2023.
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
//

import Client
import Combine
import DIComposition
import Entities
import FactoryKit
import Foundation
import Macro
import ProtonCoreNetworking

@MainActor
final class ManageSharedShareViewModel: ObservableObject {
    @Published private(set) var itemsNumber = 0
    @Published private(set) var invitations = ShareInvites.default
    @Published private(set) var vaultMembers: [any ShareInvitee] = []
    @Published private(set) var itemMembers: [any ShareInvitee] = []
    @Published private(set) var totalNumberOfVaultMembers = 0
    @Published private(set) var totalNumberOfItemMembers = 0
    @Published private(set) var fetching = false
    @Published private(set) var loading = false
    @Published private(set) var isFreeUser = true
    @Published private(set) var isBusinessUser = false
    @Published private(set) var itemSharingAllowed = false
    @Published private(set) var currentUserEmail: String?
    @Published var newOwner: NewOwner?
    @Published var selectedGroupInfo: GroupInfo?

    @Published private var groups = [String: GroupInfo]()

    private let getVaultItemCount = resolve(\UseCasesContainer.getVaultItemCount)
    private let getUsersLinkedToShare = resolve(\UseCasesContainer.getUsersLinkedToShare)
    private let getPendingInvitationsForShare = resolve(\UseCasesContainer.getPendingInvitationsForShare)
    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private let revokeInvitation = resolve(\UseCasesContainer.revokeInvitation)
    private let revokeNewUserInvitation = resolve(\UseCasesContainer.revokeNewUserInvitation)
    private let sendInviteReminder = resolve(\UseCasesContainer.sendInviteReminder)
    private let updateUserShareRole = resolve(\UseCasesContainer.updateUserShareRole)
    private let revokeUserShareAccess = resolve(\UseCasesContainer.revokeUserShareAccess)
    private let transferVaultOwnership = resolve(\UseCasesContainer.transferVaultOwnership)
    private let canUserTransferVaultOwnership = resolve(\UseCasesContainer.canUserTransferVaultOwnership)
    private let promoteNewUserInvite = resolve(\UseCasesContainer.promoteNewUserInvite)
    private let userManager = resolve(\ServiceContainer.userManager)
    private let logger = resolve(\ToolingContainer.logger)
    private let syncEventLoop = resolve(\ServiceContainer.syncEventLoop)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let accessRepository = resolve(\RepositoryContainer.accessRepository)
    private var fetchingTask: Task<Void, Never>?
    @LazyInjected(\RepositoryContainer.organizationRepository)
    private var organizationRepository
    @LazyInjected(\RepositoryContainer.groupRepository) private var groupRepository

    @LazyInjected(\UseCasesContainer.getFeatureFlagStatus)
    private var getFeatureFlagStatus

    var managerAsAdmin: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passRenameAdminToManager)
    }

    var reachedLimit: Bool {
        numberOfInvitesLeft <= 0
    }

    var numberOfInvitesLeft: Int {
        max(share.maxMembers - (vaultMembers.count + invitations.totalNumberOfInvites), 0)
    }

    var showInvitesLeft: Bool {
        guard !fetching, !isBusinessUser else {
            return false
        }
        if isFreeUser {
            return !reachedLimit
        }
        return reachedLimit
    }

    var showVaultLimitMessage: Bool {
        guard !fetching, isFreeUser else {
            return false
        }

        return reachedLimit
    }

    private let displayType: ManageSharedDisplay

    var share: Share {
        switch displayType {
        case let .item(share, _), let .vault(share):
            share
        }
    }

    private var item: ItemContent? {
        switch displayType {
        case let .item(_, item):
            item

        default:
            nil
        }
    }

    init(display: ManageSharedDisplay) {
        displayType = display
    }

    func setUp() async {
        defer { loading = false }
        loading = true
        do {
            let userData = try await userManager.getUnwrappedActiveUserData()
            currentUserEmail = userData.user.email
            let userId = userData.user.ID
            let plan = try await accessRepository.getPlan(userId: userId)

            isFreeUser = plan.isFreeUser
            isBusinessUser = plan.isBusinessUser
            if isBusinessUser,
               let org = try await organizationRepository.getOrganization(userId: userId),
               let itemShareMode = org.settings?.itemShareMode {
                itemSharingAllowed = itemShareMode == .enabled
            }

            if let userGroupInfos = try? await groupRepository.getGroupsInfos(userId: userId) {
                for groupInfo in userGroupInfos {
                    if let address = groupInfo.group.address {
                        groups[address.email] = groupInfo
                    }
                }
            }
        } catch {
            logger.error(error)
            display(error: error)
        }
    }

    func isCurrentUser(_ invitee: any ShareInvitee) -> Bool {
        userManager.currentActiveUser.value?.user.email == invitee.email
    }

    func currentUserHasDirectMembership() -> Bool {
        vaultMembers.contains { $0.email == userManager.currentActiveUser.value?.user.email }
    }

    func isInCurrentGroup(_ invitee: any ShareInvitee) -> Bool {
        guard let currentEmail = userManager.currentActiveUser.value?.user.email,
              let members = groups[invitee.email]?.members else {
            return false
        }

        return members.compactMap(\.email).contains(currentEmail)
    }

    func shareWithMorePeople(iSharingVault: Bool) {
        let typeOfSharing: SharingElementData
        if iSharingVault {
            typeOfSharing = .vault(share)
        } else if let item {
            typeOfSharing = .item(item: item, share: share)
        } else {
            return
        }

        setShareInviteVault(with: typeOfSharing)
        router.present(for: .sharingFlow(.none))
    }

    func fetchShareInformation(displayFetchingLoader: Bool = false) {
        fetchingTask?.cancel()
        fetchingTask = Task { [weak self] in
            guard let self else {
                return
            }
            if displayFetchingLoader {
                fetching = true
            } else {
                loading = true
            }
            defer {
                if displayFetchingLoader {
                    fetching = false
                } else {
                    loading = false
                }
            }
            do {
                try await doFetchShareInformation()
            } catch {
                display(error: error)
                logger.error(message: "Failed to fetch the current share informations", error: error)
            }
        }
    }

    func canTransferOwnership(to invitee: any ShareInvitee) -> Bool {
        guard invitee.shareType == .vault, !invitee.owner else {
            return false
        }
        return canUserTransferVaultOwnership(for: share, to: invitee)
    }

    // swiftformat:disable hoistAwait
    // swiftlint:disable cyclomatic_complexity
    func handle(option: ShareInviteeOption) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                let shareId = share.shareId
                switch option {
                case let .remindExistingUserInvitation(inviteId):
                    try await execute(await sendInviteReminder(userId: userId,
                                                               shareId: shareId,
                                                               inviteId: inviteId),
                                      shouldForceSync: false)

                case let .cancelExistingUserInvitation(inviteId):
                    try await execute(await revokeInvitation(userId: userId,
                                                             shareId: share.shareId,
                                                             inviteId: inviteId))

                case let .cancelNewUserInvitation(inviteId):
                    try await execute(await revokeNewUserInvitation(userId: userId,
                                                                    shareId: shareId,
                                                                    inviteId: inviteId))

                case let .confirmAccess(access):
                    try await execute(await promoteNewUserInvite(share: share,
                                                                 inviteId: access.inviteId,
                                                                 email: access.email))

                case let .updateRole(shareId, role):
                    try await execute(await updateUserShareRole(userShareId: shareId,
                                                                shareId: share.shareId,
                                                                shareRole: role))

                case let .revokeAccess(shareId):
                    try await execute(await revokeUserShareAccess(with: shareId,
                                                                  and: share.shareId))

                case let .confirmTransferOwnership(newOwner):
                    self.newOwner = newOwner

                case let .transferOwnership(newOwner):
                    let element = UIElementDisplay.successMessage(#localized("Vault has been transferred"),
                                                                  config: nil)
                    try await execute(await transferVaultOwnership(newOwnerID: newOwner.shareId,
                                                                   shareId: share.shareId),
                                      elementDisplay: element)

                case let .showGroupMembers(invitee):
                    guard let groupInfo = groups[invitee.email],
                          let members = groupInfo.members,
                          !members.isEmpty else {
                        return
                    }
                    selectedGroupInfo = groupInfo
                }
            } catch {
                logger.error(error)
                display(error: error)
            }
        }
    }

    // swiftlint:enable cyclomatic_complexity
    // swiftformat:enable hoistAwait

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func inviteTitle(_ invite: any ShareInvitee) -> String {
        if let groupInfo = groups[invite.email] {
            if let members = groupInfo.members {
                #localized("%@ (%lld members)", groupInfo.group.name, members.count)
            } else {
                groupInfo.group.name
            }
        } else {
            invite.email
        }
    }
}

private extension ManageSharedShareViewModel {
    func execute(_ action: @Sendable @autoclosure () async throws -> Void,
                 shouldForceSync: Bool = true,
                 elementDisplay: UIElementDisplay? = nil) async throws {
        defer { loading = false }
        loading = true

        try await action()
        try await doFetchShareInformation()

        if let elementDisplay {
            router.display(element: elementDisplay)
        }

        if shouldForceSync {
            syncEventLoop.forceSync()
        }
    }

    func doFetchShareInformation() async throws {
        itemsNumber = getVaultItemCount(for: share.id)
        if Task.isCancelled {
            return
        }

        async let getPendingInvitations = fetchPendingInvitations()
        async let getMembers = if case .vault = displayType {
            getUsersLinkedToShare(with: share).shares
        } else {
            fetchUsersLinkedToShare()
        }

        let (allInvitations, allMembers) = try await (getPendingInvitations, getMembers)

        itemMembers.removeAll()
        vaultMembers.removeAll()
        for invitation in allInvitations.invitees {
            if invitation.shareType == .vault {
                vaultMembers.append(invitation)
            } else if invitation.shareType == .item {
                itemMembers.append(invitation)
            }
        }

        for member in allMembers {
            if member.shareType == .vault {
                vaultMembers.append(member)
            } else if member.shareType == .item {
                itemMembers.append(member)
            }
        }

        itemMembers = itemMembers.sorted { $0.email > $1.email }
        vaultMembers = vaultMembers.sorted { $0.email > $1.email }

        setTotalNumberOfMembers()
    }

    func setTotalNumberOfMembers() {
        totalNumberOfVaultMembers = vaultMembers.reduce(0) { $0 + (groups[$1.email]?.members?.count ?? 1) }
        totalNumberOfItemMembers = itemMembers.reduce(0) { $0 + (groups[$1.email]?.members?.count ?? 1) }
    }
}

private extension ManageSharedShareViewModel {
    func display(error: any Error) {
        router.display(element: .displayErrorBanner(error))
    }

    func fetchUsersLinkedToShare() async throws -> [UserShareInfos] {
        guard let item else {
            return []
        }
        return try await getUsersLinkedToShare(with: share, itemId: item.itemId).shares
    }

    func fetchPendingInvitations() async throws -> ShareInvites {
        guard share.isManager else {
            return .default
        }
        let userId = try await userManager.getActiveUserId()
        return try await getPendingInvitationsForShare(userId: userId, shareId: share.shareId)
    }
}
