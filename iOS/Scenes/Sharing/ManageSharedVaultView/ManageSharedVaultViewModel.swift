//
//
// ManageSharedVaultViewModel.swift
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
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreNetworking

final class ManageSharedVaultViewModel: ObservableObject, @unchecked Sendable {
    private(set) var vault: Vault
    @Published private(set) var itemsNumber = 0
    @Published private(set) var invitations = ShareInvites.default
    @Published private(set) var members: [UserShareInfos] = []
    @Published private(set) var fetching = false
    @Published private(set) var loading = false
    @Published var newOwner: NewOwner?

    private let getVaultItemCount = resolve(\UseCasesContainer.getVaultItemCount)
    private let getVaultInfos = resolve(\UseCasesContainer.getVaultInfos)
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
    private let canUserShareVault = resolve(\UseCasesContainer.canUserShareVault)
    private let promoteNewUserInvite = resolve(\UseCasesContainer.promoteNewUserInvite)
    private let userData = resolve(\SharedDataContainer.userData)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private var fetchingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var canShare: Bool {
        canUserShareVault(for: vault)
    }

    init(vault: Vault) {
        self.vault = vault
        setUp()
    }

    func isCurrentUser(_ invitee: any ShareInvitee) -> Bool {
        userData.user.email == invitee.email
    }

    func isOwnerAndCurrentUser(_ invitee: any ShareInvitee) -> Bool {
        vault.isOwner && isCurrentUser(invitee)
    }

    func shareWithMorePeople() {
        router.present(for: .sharingFlow(.none))
    }

    func fetchShareInformation(displayFetchingLoader: Bool = false) {
        fetchingTask?.cancel()
        fetchingTask = Task { @MainActor [weak self] in
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
        canUserTransferVaultOwnership(for: vault, to: invitee)
    }

    // swiftformat:disable all
    // swiftformat is confused when an async function takes an async autoclosure
    func handle(option: ShareInviteeOption) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                switch option {
                case let .remindExistingUserInvitation(inviteId):
                    try await execute(await sendInviteReminder(with: vault.shareId,
                                                               and: inviteId),
                                      shouldForceSync: false)

                case let .cancelExistingUserInvitation(inviteId):
                    try await execute(await revokeInvitation(with: vault.shareId,
                                                             and: inviteId))

                case let .cancelNewUserInvitation(inviteId):
                    try await execute(await revokeNewUserInvitation(with: vault.shareId,
                                                                    and: inviteId))

                case let .confirmAccess(access):
                    try await execute(await promoteNewUserInvite(vault: vault,
                                                                 inviteId: access.inviteId,
                                                                 email: access.email))

                case let .updateRole(shareId, role):
                    try await execute(await updateUserShareRole(userShareId: shareId,
                                                                shareId: vault.shareId,
                                                                shareRole: role),
                                      shouldForceSync: false)

                case let .revokeAccess(shareId):
                    try await execute(await revokeUserShareAccess(with: shareId,
                                                                  and: vault.shareId))

                case let .confirmTransferOwnership(newOwner):
                    self.newOwner = newOwner

                case let .transferOwnership(newOwner):
                    let element = UIElementDisplay.successMessage(
                        #localized("Vault has been transferred"),
                        config: nil)
                    try await execute(
                        await transferVaultOwnership(newOwnerID: newOwner.shareId,
                                                     shareId: vault.shareId),
                        elementDisplay: element)
                }
            } catch {
                logger.error(error)
                display(error: error)
            }
        }
    }
    // swiftformat:enable all
}

private extension ManageSharedVaultViewModel {
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
        itemsNumber = getVaultItemCount(for: vault)
        if Task.isCancelled {
            return
        }
        let shareId = vault.shareId
        if vault.isAdmin {
            invitations = try await getPendingInvitationsForShare(with: shareId)
        }
        members = try await getUsersLinkedToShare(with: shareId)
    }
}

private extension ManageSharedVaultViewModel {
    func setUp() {
        setShareInviteVault(with: .existing(vault))

        getVaultInfos(for: vault.id)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vaultInfos in
                guard let self, vaultInfos != vault else {
                    return
                }
                vault = vaultInfos
                fetchShareInformation()
                loading = false
            }
            .store(in: &cancellables)
    }

    func display(error: Error) {
        router.display(element: .displayErrorBanner(error))
    }
}

extension ShareInvites {
    var invitees: [any ShareInvitee] {
        exisingInvites + newInvites
    }
}

// MARK: Conformances to ShareInvitee

extension UserShareInfos: ShareInvitee {
    public var email: String {
        userEmail
    }

    public var subtitle: String {
        if owner {
            #localized("Owner")
        } else {
            shareRole.title
        }
    }

    public var isPending: Bool {
        false
    }

    public var isAdmin: Bool {
        shareRole == .admin
    }

    public var options: [ShareInviteeOption] {
        [
            .updateRole(shareId: shareID, role: shareRole),
            .confirmTransferOwnership(.init(email: userEmail, shareId: shareID)),
            .revokeAccess(shareId: shareID)
        ]
    }
}

extension ShareExisingUserInvite: ShareInvitee {
    public var email: String {
        invitedEmail
    }

    public var subtitle: String {
        #localized("Invitation sent")
    }

    public var isPending: Bool {
        true
    }

    public var isAdmin: Bool {
        shareRole == .admin
    }

    public var options: [ShareInviteeOption] {
        [
            .remindExistingUserInvitation(inviteId: inviteID),
            .cancelExistingUserInvitation(inviteId: inviteID)
        ]
    }
}

extension ShareNewUserInvite: ShareInvitee {
    public var email: String {
        invitedEmail
    }

    public var subtitle: String {
        switch inviteState {
        case .waitingForAccountCreation:
            #localized("Pending account creation")
        case .accountCreated:
            shareRole.title
        }
    }

    public var isPending: Bool {
        true
    }

    public var isAdmin: Bool {
        shareRole == .admin
    }

    public var options: [ShareInviteeOption] {
        switch inviteState {
        case .waitingForAccountCreation:
            [
                .cancelNewUserInvitation(inviteId: newUserInviteID)
            ]

        case .accountCreated:
            [
                .cancelNewUserInvitation(inviteId: newUserInviteID),
                .confirmAccess(.init(inviteId: newUserInviteID, email: invitedEmail))
            ]
        }
    }
}
