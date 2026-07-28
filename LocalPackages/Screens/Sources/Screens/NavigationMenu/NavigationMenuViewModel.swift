//
//
// NavigationMenuViewModel.swift
// Proton Pass - Created on 27/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Core
import DIComposition
import Entities
import FactoryKit
import Foundation
import Macro
import Observation
import ProtonCoreLogin
import Stores

private extension NavigationMenuViewModel {
    @MainActor
    struct Count {
        let all: Int
        let vaultCounts: [String: Int]
        let sharedWithMe: Int
        let sharedByMe: Int
        let trashed: Int

        init(appContentManager: AppContentManager) {
            guard let sharesData = appContentManager.state.loadedContent else {
                all = 0
                vaultCounts = [:]
                sharedWithMe = 0
                sharedByMe = 0
                trashed = 0
                return
            }
            var all = 0
            var vaultCounts = [String: Int]()
            let hiddenShareIds = sharesData.hiddenSharesIds

            for shareContent in sharesData.shares.values where shareContent.share.vaultContent != nil {
                if !shareContent.share.hidden {
                    all += shareContent.itemCount
                }
                vaultCounts[shareContent.share.shareId] = shareContent.itemCount
            }
            self.all = all + sharesData.itemsSharedWithMe.count(where: { $0.state == .active })
            self.vaultCounts = vaultCounts
            sharedWithMe = sharesData.itemsSharedWithMe.count
            sharedByMe = sharesData.itemsSharedByMe.count
            trashed = sharesData.trashedItems.count(where: { !hiddenShareIds.contains($0.shareId) })
        }
    }
}

@MainActor
@Observable
public final class NavigationMenuViewModel: DeinitPrintable {
    private(set) var loading = false
    private(set) var state = AppContentState.loading
    private(set) var organization: Entities.Organization?
    private(set) var hiddenShareIds = Set<String>()
    private(set) var mode: Mode = .view
    private(set) var folderLimits = FolderLimits.default
    private(set) var visibleVaults: [ShareContent] = []
    private(set) var hiddenVaults: [ShareContent] = []
    private(set) var hideShowVaultSupported = false
    private(set) var folderSupported = false

    var containerToDelete: ActionnableContainer?
    var folderAction: FolderAction?

    let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)

    private let setShareInviteVault = dependency(\UseCasesContainer.setShareInviteVault)
    private let getUserShareStatus = dependency(\UseCasesContainer.getUserShareStatus)
    private let canUserPerformActionOnVault = dependency(\UseCasesContainer.canUserPerformActionOnVault)
    private let leaveShare = dependency(\UseCasesContainer.leaveShare)
    private let syncEventLoop = dependency(\ServiceContainer.syncEventLoop)
    private let logger = dependency(\ToolingContainer.logger)
    private let appContentManager = dependency(\ServiceContainer.appContentManager)
    private let userManager = dependency(\ServiceContainer.userManager)
    private let accessRepository = dependency(\RepositoryContainer.accessRepository)
    private let organizationRepository = dependency(\RepositoryContainer.organizationRepository)
    private let getFeatureFlagStatus = dependency(\UseCasesContainer.getFeatureFlagStatus)
    private let reorganizeVaults = dependency(\UseCasesContainer.reorganizeVaults)
    private let itemRepository = dependency(\RepositoryContainer.itemRepository)
    private let checkVaultCreationAllowance = dependency(\UseCasesContainer.checkVaultCreationAllowance)

    private var userData: UserData?
    private var plan: Plan?
    private var count: Count
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    private var orderedVaults: [ShareContent] = []

    var expandedContainerIds = Set<String>() {
        didSet {
            persist()
        }
    }

    var shareSelection: ShareSelectionPayload? {
        didSet {
            guard let shareSelection, shareSelection != oldValue else { return }
            select(.precise(shareSelection))
        }
    }

    func shareContent(for shareId: String) -> ShareContent? {
        orderedVaults.first { $0.share.id == shareId }
    }

    func canAddFolderAtVaultRoot(for vault: Share) -> Bool {
        guard let content = shareContent(for: vault.id) else { return false }
        return content.canAddFolder(in: vault.id, limits: folderLimits)
    }

    func canAddSubFolder(in folder: FolderUiModel, content: ShareContent) -> Bool {
        content.canAddFolder(in: folder.folderId, limits: folderLimits)
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

    public enum Mode {
        case view, organise

        public var isView: Bool {
            if case .view = self {
                true
            } else {
                false
            }
        }

        public var isOrganise: Bool {
            if case .organise = self {
                true
            } else {
                false
            }
        }
    }

    public init() {
        state = appContentManager.state
        count = .init(appContentManager: appContentManager)
        recomputeVaults()
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

    func canMoveItems(folder: FolderUiModel) -> Bool {
        guard let content = shareContent(for: folder.shareId),
              canUserPerformActionOnVault(for: content.share) else { return false }
        return !content.flattenedItems(from: folder.folderId).isEmpty
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
    }

    func shouldShowToggleArrow(for content: ShareContent) -> Bool {
        guard content.isReadOnly else {
            return true
        }

        return content.totalFolderCount > 0
    }
}

// MARK: - Public APIs

extension NavigationMenuViewModel {
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
                router.display(element: .infosMessage(infoMessage(for: container)))
            } catch {
                handle(error)
            }
        }
    }

    func selectedFolderToMove(folderToMove: FolderToMove) {
        router.present(for: .moveFolder(folderToMove))
    }

    func moveAllItemsInFolder(_ folder: FolderUiModel) {
        router.present(for: .moveItemsBetweenVaults(.allItemsInFolder(folder)))
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
                router.display(element: .successMessage(#localized("All items restored", bundle: .module),
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
                router.display(element: .infosMessage(#localized("All items permanently deleted", bundle: .module),
                                                      config: .refresh))
                logger.info("Emptied all trashed items")
            } catch {
                handle(error)
            }
        }
    }

    func itemCount(for selection: ShareSelection) -> Int {
        switch selection {
        case .all:
            count.all

        case let .precise(selection):
            count.vaultCounts[selection.share.shareId] ?? 0

        case .sharedWithMe:
            count.sharedWithMe

        case .sharedByMe:
            count.sharedByMe

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
        recomputeVaults()
    }

    func updateMode(_ mode: Mode) {
        if mode.isOrganise {
            hiddenShareIds = Set(orderedVaults.compactMap { content in
                guard content.share.hidden else { return nil }
                return content.share.shareId
            })
        }
        self.mode = mode
        recomputeVaults()
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

extension NavigationMenuViewModel {
    func editFolder(_ folder: FolderUiModel, name: String) async throws {
        let userId = try await userManager.getActiveUserId()
        try await appContentManager.editFolder(userId: userId,
                                               shareId: folder.shareId,
                                               folderId: folder.folderId,
                                               name: name)
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

    func folderCreateAndEdition(name: String) {
        guard let folderAction,
              !name.isEmpty else { return }
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
                    try await createFolder(share: share, parentFolderId: parentFolderId, name: name)

                case let .edit(folder):
                    try await editFolder(folder, name: name)
                }
            } catch {
                handle(error)
            }
        }
    }
}

// MARK: - Private APIs

private extension NavigationMenuViewModel {
    func setUp() {
        folderSupported = getFeatureFlagStatus(for: FeatureFlagType.passFolder)

        if let userId = userManager.activeUserId {
            expandedContainerIds = Self.loadSet(for: userId)
        }

        if case let .precise(payload) = appContentManager.shareSelection {
            shareSelection = payload
        }

        if let newFolderLimits = accessRepository.access.value?.access.plan.folderLimits {
            folderLimits = newFolderLimits
        }

        appContentManager.$state
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newState in
                guard let self, newState != state else { return }
                state = newState
                count = .init(appContentManager: appContentManager)
                refreshHiddenShareIds()
                recomputeVaults()
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
                if let newFolderLimits = accessRepository.access.value?.access.plan.folderLimits,
                   newFolderLimits != folderLimits {
                    folderLimits = newFolderLimits
                }
            }
            .store(in: &cancellables)
    }

    func recomputeVaults() {
        let ordered: [ShareContent] = if case let .loaded(data) = state {
            data.filteredOrderedVaults
        } else {
            []
        }
        orderedVaults = ordered
        if mode == .view {
            visibleVaults = ordered.filter { !$0.share.hidden }
        } else {
            visibleVaults = ordered.filter { !hiddenShareIds.contains($0.id) }
        }
        hiddenVaults = ordered.filter { hiddenShareIds.contains($0.id) }
        hideShowVaultSupported = getFeatureFlagStatus(for: FeatureFlagType.passHideShowVault)
            || ordered.contains(where: \.share.hidden)
    }

    func handle(_ error: any Error,
                file: String = #file,
                function: String = #function,
                line: UInt = #line,
                column: UInt = #column) {
        logger.error(error, file: file, function: function, line: line, column: column)
        router.display(element: .displayErrorBanner(error))
    }

    func persist() {
        if let userId = userManager.activeUserId {
            Self.saveSet(expandedContainerIds,
                         for: userId)
        }
    }

    func infoMessage(for container: ActionnableContainer) -> String {
        if container.isVault {
            #localized("Vault « %@ » deleted", bundle: .module, container.name ?? "unknown")
        } else {
            #localized("Folder « %@ » deleted", bundle: .module, container.name ?? "unknown")
        }
    }
}

private extension NavigationMenuViewModel {
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
