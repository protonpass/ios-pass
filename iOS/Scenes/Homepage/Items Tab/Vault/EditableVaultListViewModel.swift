//
// EditableVaultListViewModel.swift
// Proton Pass - Created on 08/03/2023.
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
import Combine
import Core
import Entities
import FactoryKit
import Foundation
import Macro
import ProtonCoreLogin

private extension EditableVaultListViewModel {
    struct VaultCount {
        let shareId: String
        let value: Int
    }

    @MainActor
    struct Count {
        let all: Int
        let vaultCounts: [VaultCount]
        let trashed: Int

        init(appContentManager: AppContentManager) {
            guard let sharesData = appContentManager.state.loadedContent else {
                all = 0
                vaultCounts = []
                trashed = 0
                return
            }
            var all = 0
            var vaultCounts = [VaultCount]()
            let hiddenShareIds = sharesData.hiddenSharesIds

            for shareContent in sharesData.visibleShareContents where shareContent.share.vaultContent != nil {
                if !shareContent.share.hidden {
                    all += shareContent.itemCount
                }
                vaultCounts.append(.init(shareId: shareContent.share.shareId, value: shareContent.itemCount))
            }
            self.all = all
            self.vaultCounts = vaultCounts
            trashed = sharesData.trashedItems.count(where: { !hiddenShareIds.contains($0.shareId) })
        }
    }
}

@MainActor
final class EditableVaultListViewModel: ObservableObject, DeinitPrintable {
    @Published private(set) var loading = false
    @Published private(set) var state = AppContentState.loading
    @Published private(set) var organization: Entities.Organization?
    @Published private(set) var hiddenShareIds = Set<String>()
    @Published private(set) var mode: Mode = .view
    @Published private var userData: UserData?
    @Published private var plan: Plan?
    @Published var expandedContainerIds = Set<String>() {
        didSet {
            persist()
        }
    }

    @Published var shareSelection: ShareSelectionPayload?
    @Published var containerToDelete: ActionnableContainer?
    @Published var folderAction: FolderAction?
    @Published var folderName: String = ""

    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private let getUserShareStatus = resolve(\UseCasesContainer.getUserShareStatus)
    private let canUserPerformActionOnVault = resolve(\UseCasesContainer.canUserPerformActionOnVault)
    private let leaveShare = resolve(\UseCasesContainer.leaveShare)
    private let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRepositoryContainer.accessRepository)
    private var accessRepository
    @LazyInjected(\SharedRepositoryContainer.organizationRepository)
    private var organizationRepository
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus)
    private var getFeatureFlagStatus
    @LazyInjected(\UseCasesContainer.reorganizeVaults)
    private var reorganizeVaults
    @LazyInjected(\SharedRepositoryContainer.itemRepository)
    private var itemRepository

    @LazyInjected(\UseCasesContainer.checkVaultCreationAllowance)
    private var checkVaultCreationAllowance

    private var count: Count
    private var cancellables = Set<AnyCancellable>()

    private var orderedVaults: [ShareContent] {
        if case let .loaded(data) = state {
            data.filteredOrderedVaults
        } else {
            []
        }
    }

    var visibleVaults: [ShareContent] {
        if mode == .view {
            orderedVaults.filter { !$0.share.hidden }
        } else {
            orderedVaults.filter { !hiddenShareIds.contains($0.id) }
        }
    }

    var hiddenVaults: [ShareContent] {
        orderedVaults.filter { hiddenShareIds.contains($0.id) }
    }

    var hideShowVaultSupported: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passHideShowVault) ||
            orderedVaults.contains(where: \.share.hidden)
    }

    var folderSupported: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passFolder)
    }

    func shareContent(for shareId: String) -> ShareContent? {
        orderedVaults.first { $0.share.id == shareId }
    }

    func canAddFolderAtVaultRoot(for vault: Share) -> Bool {
        guard let content = shareContent(for: vault.id) else { return false }
        return content.canAddFolder(in: vault.id)
    }

    func canAddSubFolder(in folder: FolderUiModel, content: ShareContent) -> Bool {
        content.canAddFolder(in: folder.folderId)
    }

    var vaultCreationAllowed: Bool {
        checkVaultCreationAllowance(userData: userData,
                                    organization: organization,
                                    vaultCount: appContentManager.getVaultsCount())
    }

    var hasTrashItems: Bool {
        count.trashed > 0
    }

    var shouldUpsell: Bool {
        plan?.shouldUpsell ?? false
    }

    var trashedAliasesCount: Int {
        guard let sharesDatas = appContentManager.state.loadedContent else {
            return 0
        }
        return sharesDatas.trashedItems.count
    }

    enum Mode {
        case view, organise

        var isView: Bool {
            if case .view = self {
                true
            } else {
                false
            }
        }

        var isOrganise: Bool {
            if case .organise = self {
                true
            } else {
                false
            }
        }
    }

    init() {
        count = .init(appContentManager: appContentManager)
        setUp()
    }

    deinit {
        print(deinitMessage)
    }

    func select(_ selection: ShareSelection) {
        guard !appContentManager.isSelected(selection) else {
            return
        }
        appContentManager.select(selection)
    }

    func isSelected(_ selection: ShareSelection) -> Bool {
        appContentManager.isSelected(selection)
    }

    func canShare(vault: Share) -> Bool {
        getUserShareStatus(for: vault) != .cantShare && !vault.shared
    }

    func canEdit(vault: Share) -> Bool {
        canUserPerformActionOnVault(for: vault) && vault.isOwner
    }

    func canMoveItems(vault: Share) -> Bool {
        canUserPerformActionOnVault(for: vault)
    }

    func canSelectVault(selection: ShareSelection) -> Bool {
        guard selection == .sharedByMe || selection == .sharedWithMe else {
            return true
        }
        return itemCount(for: selection) > 0
    }

    func upgradeSubscription() {
        router.present(for: .upgradeFlow)
    }

    func toggleDisplayContainerContent(containerId: String) {
        if expandedContainerIds.remove(containerId) == nil {
            expandedContainerIds.insert(containerId)
        }
    }

    func cleanActions() {
        folderAction = nil
        folderName = ""
    }
}

// MARK: - Public APIs

extension EditableVaultListViewModel {
    func delete(container: ActionnableContainer) {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                switch container {
                case let .vault(vault):
                    try await appContentManager.delete(vault: vault)
                case let .folder(folder):
                    try await appContentManager.deleteFolder(userId: userId,
                                                             shareId: folder.shareId,
                                                             folderId: folder.folderId)
                    // If the folder is currently
                    if let preciseSelectionPayload = appContentManager.shareSelection.preciseSelectionPayload,
                       preciseSelectionPayload.folder == folder {
                        appContentManager.select(.precise(.init(share: preciseSelectionPayload.share,
                                                                folder: nil)))
                    }
                }
                await appContentManager.refresh(userId: userId)
                router.display(element: .infosMessage(#localized("%@ « %@ » deleted",
                                                                 container.isVault ? "Vault" : "Folder",
                                                                 container.name ?? "unknown")))
            } catch {
                handle(error)
            }
        }
    }

    func selectedFolderToMove(folderToMove: FolderToMove) {
        router.present(for: .moveFolder(folderToMove))
    }

    func createNewVault() {
        router.present(for: .vaultCreateEdit(vault: nil))
    }

    func edit(vault: Share) {
        router.present(for: .vaultCreateEdit(vault: vault))
    }

    func share(vault: Share) {
        if getUserShareStatus(for: vault) == .canShare {
            setShareInviteVault(with: .vault(vault))
            router.present(for: .sharingFlow(.none))
        } else {
            router.present(for: .upselling(.default))
        }
    }

    func leaveVault(vault: Share) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                try await leaveShare(userId: userId, with: vault.shareId)
                syncEventLoop.forceSync()
            } catch {
                handle(error)
            }
        }
    }

    func restoreAllTrashedItems() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                logger.trace("Restoring all trashed items")
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.restoreAllTrashedItems(userId: userId)
                router.display(element: .successMessage(#localized("All items restored"),
                                                        config: .refresh))
                logger.info("Restored all trashed items")
            } catch {
                handle(error)
            }
        }
    }

    func emptyTrash() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                logger.trace("Emptying all trashed items")
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.permanentlyDeleteAllTrashedItems(userId: userId)
                router.display(element: .infosMessage(#localized("All items permanently deleted"),
                                                      config: .refresh))
                logger.info("Emptied all trashed items")
            } catch {
                handle(error)
            }
        }
    }

    func itemCount(for selection: ShareSelection) -> Int {
        let itemsSharedWithMe = appContentManager.state.loadedContent?.itemsSharedWithMe ?? []
        let activeItemsSharedWithMeCount = itemsSharedWithMe.count(where: { $0.state == .active })

        return switch selection {
        case .all:
            count.all + activeItemsSharedWithMeCount
        case let .precise(selection):
            count.vaultCounts.first { $0.shareId == selection.share.shareId }?.value ?? 0
        case .sharedWithMe:
            itemsSharedWithMe.count
        case .sharedByMe:
            appContentManager.state.loadedContent?.itemsSharedByMe.count ?? 0
        case .trash:
            count.trashed
        }
    }

    func refreshHiddenShareIds() {
        // Remove stale shareID from hidden shareID set
        if case let .loaded(data) = state {
            let applicableShareIds = data.shares.values.map(\.share.shareId)
            for shareId in hiddenShareIds where !applicableShareIds.contains(shareId) {
                hiddenShareIds.remove(shareId)
            }
        }
    }

    func isLastVisibleVault(_ share: Share) -> Bool {
        if let lastVisibleVault = visibleVaults
            .last(where: { !hiddenShareIds.contains($0.share.shareId) }) {
            lastVisibleVault.share.shareId == share.shareId
        } else {
            false
        }
    }

    func isLastHiddenVault(_ share: Share) -> Bool {
        if let lastHiddenVault = hiddenVaults.last(where: { hiddenShareIds.contains($0.share.shareId) }) {
            lastHiddenVault.share.shareId == share.shareId
        } else {
            false
        }
    }

    func hideOrUnhide(share: Share) {
        let id = share.shareId
        if hiddenShareIds.contains(id) {
            hiddenShareIds.remove(id)
        } else {
            hiddenShareIds.insert(id)
        }
    }

    func updateMode(_ mode: Mode) {
        if mode.isOrganise {
            hiddenShareIds = Set(orderedVaults.compactMap { content in
                guard content.share.hidden else { return nil }
                return content.share.shareId
            })
        }
        self.mode = mode
    }

    func applyVaultsOrganizations() {
        guard case let .loaded(data) = state else { return }
        Task { [weak self] in
            guard let self else { return }
            loading = true
            do {
                if try await reorganizeVaults(currentShares: data.shares.map(\.value.share),
                                              hiddenShareIds: hiddenShareIds) {
                    let userId = try await userManager.getActiveUserId()
                    try await appContentManager.localFullSync(userId: userId)
                    try await itemRepository.refreshPinnedItemDataStream()
                }
                loading = false
                updateMode(.view)
            } catch {
                loading = false
                handle(error)
            }
        }
    }
}

// MARK: - Folder actions

extension EditableVaultListViewModel {
    func editFolder(_ folder: FolderUiModel) async throws {
        let userId = try await userManager.getActiveUserId()
        try await appContentManager.editFolder(userId: userId,
                                               shareId: folder.shareId,
                                               folderId: folder.folderId,
                                               name: folderName)
    }

    func createFolder(share: Share, parentFolderId: String?, name: String) async throws {
        let userId = try await userManager.getActiveUserId()
        try await appContentManager.createFolder(userId: userId,
                                                 shareId: share.id,
                                                 parentFolderId: parentFolderId,
                                                 name: name)
        let completeParentId = if let parentFolderId {
            "\(parentFolderId)\(share.id)"
        } else {
            share.id
        }
        expandedContainerIds.insert(completeParentId)
    }

    func folderCreateAndEdition() {
        guard let folderAction,
              !folderName.isEmpty else { return }
        // should not alow creation why other is not finished
        Task { [weak self] in
            guard let self else { return }
            defer {
                loading = false
                cleanActions()
            }
            loading = true
            do {
                switch folderAction {
                case let .createNewFolder(share, parentFolderId):
                    try await createFolder(share: share, parentFolderId: parentFolderId, name: folderName)
                case let .edit(folder):
                    try await editFolder(folder)
                }
            } catch {
                handle(error)
            }
        }
    }
}

// MARK: - Private APIs

private extension EditableVaultListViewModel {
    func setUp() {
        if let userId = userManager.activeUserId {
            expandedContainerIds = Self.loadSet(for: userId)
        }

        if case let .precise(payload) = appContentManager.shareSelection {
            shareSelection = payload
        }

        $shareSelection
            .receive(on: DispatchQueue.main)
            .compactMap(\.self)
            .removeDuplicates()
            .sink { [weak self] shareSelection in
                guard let self else { return }
                select(.precise(shareSelection))
            }
            .store(in: &cancellables)

        appContentManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }
                state = newState
                count = .init(appContentManager: appContentManager)
                refreshHiddenShareIds()
            }
            .store(in: &cancellables)

        Task { [weak self] in
            guard let self else { return }
            do {
                let userData = try await userManager.getUnwrappedActiveUserData()
                if accessRepository.access.value?.access.plan.isBusinessUser == true {
                    organization = try await organizationRepository.getOrganization(userId: userData.user.ID)
                }
                self.userData = userData
            } catch {
                handle(error)
            }
        }

        accessRepository.access
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedAccess in
                guard let self else {
                    return
                }
                plan = updatedAccess?.access.plan
            }
            .store(in: &cancellables)
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }

    func persist() {
        if let userId = userManager.activeUserId {
            Self.saveSet(expandedContainerIds,
                         for: userId)
        }
    }
}

private extension EditableVaultListViewModel {
    static let keyPrefix = "me.pass.editablevaultlistviewmodel.set"

    static func loadSet(for userId: String) -> Set<String> {
        let key = makeKey(for: userId)
        let array = kSharedUserDefaults.stringArray(forKey: key) ?? []
        return Set(array)
    }

    static func saveSet(_ value: Set<String>,
                        for userId: String) {
        let key = makeKey(for: userId)
        kSharedUserDefaults.set(Array(value), forKey: key)
    }

    static func makeKey(for userId: String) -> String {
        "\(keyPrefix).\(userId)"
    }
}
