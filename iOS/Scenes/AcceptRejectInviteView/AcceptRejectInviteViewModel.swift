//
//
// AcceptRejectInviteViewModel.swift
// Proton Pass - Created on 27/07/2023.
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
import Screens
import Stores

@MainActor
final class AcceptRejectInviteViewModel: ObservableObject {
    @Published private(set) var invite: Invite
    @Published private(set) var vaultInfos: VaultContent?
    @Published private(set) var executingAction = false
    @Published private(set) var shouldCloseSheet = false
    private(set) var invitedGroupName = ""

    private let rejectInvitation = dependency(\UseCasesContainer.rejectInvitation)
    private let acceptInvitation = dependency(\UseCasesContainer.acceptInvitation)
    private let decodeShareVaultInformation = dependency(\UseCasesContainer.decodeShareVaultInformation)
    private let updateCachedInvitations = dependency(\UseCasesContainer.updateCachedInvitations)
    private let logger = dependency(\ToolingContainer.logger)
    private let syncEventLoop = dependency(\ServiceContainer.syncEventLoop)
    private let appContentManager = dependency(\ServiceContainer.appContentManager)
    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
    @LazyInjected(\ServiceContainer.userManager) private var userManager
    @LazyInjected(\RepositoryContainer.groupRepository) private var groupRepository
    private var cancellables = Set<AnyCancellable>()

    init(invite: Invite) {
        self.invite = invite
        setUp()
    }

    func reject() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                executingAction = false
            }

            do {
                executingAction = true
                try await rejectInvitation(invite)
                await updateCachedInvitations(for: invite.inviteToken)
                shouldCloseSheet = true
            } catch {
                logger.error(message: "Could not reject invitation \(invite)", error: error)
                display(error: error)
            }
        }
    }

    func accept() {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                executingAction = true
                _ = try await acceptInvitation(with: invite)
                await updateCachedInvitations(for: invite.inviteToken)
                syncEventLoop.forceSync()
                if case .group = invite {
                    executingAction = false
                    shouldCloseSheet = true
                }
            } catch {
                logger.error(message: "Could not accept invitation \(invite)", error: error)
                display(error: error)
                executingAction = false
            }
        }
    }
}

private extension AcceptRejectInviteViewModel {
    func setUp() {
        if invite.isVault, invite.vaultData != nil {
            decodeVaultData()
        }

        appContentManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self,
                      let sharesData = state.loadedContent,
                      let shareContent = sharesData.shares.values
                      .first(where: { $0.share.targetID == self.invite.targetID })
                else {
                    return
                }
                if !shareContent.share.isVaultRepresentation,
                   shareContent.flattenedItems(from: shareContent.id).isEmpty {
                    return
                }
                guard case .user = invite else {
                    return
                }
                displayItemPage(shareContent: shareContent)
            }.store(in: &cancellables)
    }

    func decodeVaultData() {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                vaultInfos = try await decodeShareVaultInformation(with: invite)
                if case let .group(invite) = invite {
                    let userId = try await userManager.getActiveUserId()
                    let group = try await groupRepository.getGroup(userId: userId, groupId: invite.invitedGroupID)
                    invitedGroupName = group.name
                }
            } catch {
                logger.error(message: "Could not decode vault content from invitation", error: error)
                display(error: error)
            }
        }
    }

    func display(error: any Error) {
        router.display(element: .displayErrorBanner(error))
    }

    func displayItemPage(shareContent: ShareContent) {
        guard !invite.isVault,
              let item = shareContent.allItems.first else {
            cleanup()
            return
        }
        Task { [weak self] in
            // swiftlint:disable:next discouraged_optional_self
            defer { self?.cleanup() }
            guard let self else {
                return
            }
            do {
                guard let itemContent = try await appContentManager.getItemContent(shareId: item.shareId,
                                                                                   itemId: item.itemId) else {
                    return
                }
                router.present(for: .itemDetail(itemContent))
            } catch {
                logger.error(message: "Error displaying item detail after accepting item invitation", error: error)
            }
        }
    }

    func cleanup() {
        executingAction = false
        shouldCloseSheet = true
    }
}
