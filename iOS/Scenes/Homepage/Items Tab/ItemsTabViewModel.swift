//
// ItemsTabViewModel.swift
// Proton Pass - Created on 07/03/2023.
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
import Factory
import Macro
import Screens
import SwiftUI

@MainActor
protocol ItemsTabViewModelDelegate: AnyObject {
    func itemsTabViewModelWantsToCreateNewItem(type: ItemContentType)
    func itemsTabViewModelWantsToPresentVaultList()
    func itemsTabViewModelWantsToShowTrialDetail()
    func itemsTabViewModelWantsViewDetail(of itemContent: ItemContent)
}

@MainActor
final class ItemsTabViewModel: ObservableObject, PullToRefreshable, DeinitPrintable {
    deinit { print(deinitMessage) }

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    @Published private(set) var pinnedItems: [ItemUiModel]?
    @Published private(set) var showingUpgradeAppBanner = false
    @Published private(set) var banners: [InfoBanner] = []
    @Published private(set) var shouldShowSyncProgress = false
    @Published var isEditMode = false
    @Published var itemToBePermanentlyDeleted: (any ItemTypeIdentifiable)? {
        didSet {
            if itemToBePermanentlyDeleted != nil {
                showingPermanentDeletionAlert = true
            }
        }
    }

    @Published var showingPermanentDeletionAlert = false

    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let credentialManager = resolve(\SharedServiceContainer.credentialManager)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)
    private let getPendingUserInvitations = resolve(\UseCasesContainer.getPendingUserInvitations)
    private let currentSelectedItems = resolve(\DataStreamContainer.currentSelectedItems)
    private let doTrashSelectedItems = resolve(\UseCasesContainer.trashSelectedItems)
    private let doRestoreSelectedItems = resolve(\UseCasesContainer.restoreSelectedItems)
    private let doPermanentlyDeleteSelectedItems = resolve(\UseCasesContainer.permanentlyDeleteSelectedItems)
    private let getAllPinnedItems = resolve(\UseCasesContainer.getAllPinnedItems)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)
    private let canEditItem = resolve(\SharedUseCasesContainer.canEditItem)
    private let openAutoFillSettings = resolve(\UseCasesContainer.openAutoFillSettings)
    private let shouldDisplayUpgradeAppBanner = resolve(\UseCasesContainer.shouldDisplayUpgradeAppBanner)
    private let getAppPreferences = resolve(\SharedUseCasesContainer.getAppPreferences)
    private let updateAppPreferences = resolve(\SharedUseCasesContainer.updateAppPreferences)
    private let pinItems = resolve(\SharedUseCasesContainer.pinItems)
    private let unpinItems = resolve(\SharedUseCasesContainer.unpinItems)

    let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    let itemContextMenuHandler = resolve(\SharedServiceContainer.itemContextMenuHandler)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: (any ItemsTabViewModelDelegate)?
    private var inviteRefreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    /// `PullToRefreshable` conformance
    var pullToRefreshContinuation: CheckedContinuation<Void, Never>?
    let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)

    var aliasSyncEnabled: Bool {
        getFeatureFlagStatus(with: FeatureFlagType.passSimpleLoginAliasesSync)
    }

    init() {
        setUp()
    }

    func loadPinnedItems() async {
        guard let symmetricKey = try? await symmetricKeyProvider.getSymmetricKey(),
              let newPinnedItems = try? await getAllPinnedItems()
              .compactMap({ try? $0.toItemUiModel(symmetricKey) })
        else { return }
        pinnedItems = Array(newPinnedItems.prefix(5))
    }

    func openAppOnAppStore() {
        router.navigate(to: .urlPage(urlString: Constants.appStoreUrl))
    }

    func refresh() {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let userId = try await userManager.getActiveUserId()
                vaultsManager.refresh(userId: userId)
            } catch {
                handle(error: error)
            }
        }
    }

    func continueFullSyncIfNeeded() {
        Task { [weak self] in
            guard let self else { return }
            if let userId = vaultsManager.incompleteFullSyncUserId {
                router.present(for: .fullSync)
                await vaultsManager.fullSync(userId: userId)
            }
        }
    }
}

// MARK: - Private APIs

private extension ItemsTabViewModel {
    // swiftlint:disable:next cyclomatic_complexity
    func setUp() {
        vaultsManager.attach(to: self, storeIn: &cancellables)

        vaultsManager.vaultSyncEventStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                if case .done = event {
                    shouldShowSyncProgress = false
                }
            }
            .store(in: &cancellables)

        Task { [weak self] in
            guard let self else { return }
            do {
                showingUpgradeAppBanner = try await shouldDisplayUpgradeAppBanner()
            } catch {
                handle(error: error)
            }
        }

        currentSelectedItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                objectWillChange.send()
            }
            .store(in: &cancellables)

        getPendingUserInvitations()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] invites in
                guard let self else { return }
                refreshBanners(invites)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                refreshBanners()
            }
            .store(in: &cancellables)

        // Show the progress if after 5 seconds after logging in and items are not yet loaded
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(seconds: 5)

            if await loginMethod.isManualLogIn(),
               case .loading = vaultsManager.state {
                shouldShowSyncProgress = true
            }
        }

        getAllPinnedItems()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] pinnedItems in
                guard let self else { return }
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
                        let firstPinnedItems = Array(pinnedItems.prefix(5))
                        self.pinnedItems = firstPinnedItems.compactMap { try? $0.toItemUiModel(symmetricKey) }
                    } catch {
                        handle(error: error)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func refreshBanners(_ invites: [UserInvite]? = nil) {
        inviteRefreshTask?.cancel()
        inviteRefreshTask = Task { [weak self] in
            guard let self else { return }
            var banners = [InfoBanner]()
            if let invites, !invites.isEmpty {
                if let newUserInvite = invites.first(where: { $0.fromNewUser }) {
                    router.present(for: .acceptRejectInvite(newUserInvite))
                } else {
                    banners.append(invites.toInfoBanners)
                }
            }
            if banners.isEmpty {
                await banners.append(contentsOf: localBanners())
            }
            self.banners = banners
        }
    }

    func localBanners() async -> [InfoBanner] {
        do {
            let dismissedIds = getAppPreferences().dismissedBannerIds
            var banners = [InfoBanner]()
            for banner in InfoBanner.allCases {
                if dismissedIds.contains(where: { $0 == banner.id }) {
                    continue
                }

                var shouldShow = true
                switch banner {
                case .trial:
                    let plan = try await accessRepository.getPlan()
                    shouldShow = plan.isInTrial

                case .autofill:
                    shouldShow = await !credentialManager.isAutoFillEnabled

                default:
                    break
                }

                if shouldShow {
                    banners.append(banner)
                }
            }
            return banners
        } catch {
            handle(error: error)
            return []
        }
    }

    func selectOrDeselect(_ item: ItemUiModel) {
        var items = currentSelectedItems.value
        if items.contains(item) {
            items.removeAll { $0 == item }
        } else {
            items.append(item)
        }
        currentSelectedItems.send(items)
        if items.isEmpty {
            isEditMode = false
        }
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

// MARK: - Public APIs

extension ItemsTabViewModel {
    @Sendable
    func forceSyncIfNotEditMode() async {
        if !isEditMode {
            await forceSync()
        }
    }

    func isSelected(_ item: any ItemIdentifiable) -> Bool {
        currentSelectedItems.value.contains(item)
    }

    func isEditable(_ item: any ItemIdentifiable) -> Bool {
        canEditItem(vaults: vaultsManager.getAllVaults(), item: item)
    }

    // False negative on unhandled_throwing_task rule. Double check later with newer version of SwiftLint
    // swiftlint:disable unhandled_throwing_task
    func pinSelectedItems() {
        Task { [weak self] in
            guard let self else { return }
            await performBulkAction { [weak self] items in
                guard let self else { return }
                try await pinItems(items.filter { $0.pinned == false })
            } successMessage: { items in
                #localized("%lld items successfully pinned", items.count)
            }
        }
    }

    func unpinSelectedItems() {
        Task { [weak self] in
            guard let self else { return }
            await performBulkAction { [weak self] items in
                guard let self else { return }
                try await unpinItems(items.filter(\.pinned))
            } successMessage: { items in
                #localized("%lld items successfully unpinned", items.count)
            }
        }
    }

    func presentVaultListToMoveSelectedItems() {
        let items = currentSelectedItems.value
        router.present(for: .moveItemsBetweenVaults(.selectedItems(items)))
    }

    func trashSelectedItems() {
        Task { [weak self] in
            guard let self else { return }
            await performBulkAction { [weak self] items in
                guard let self else { return }
                try await doTrashSelectedItems(items)
            } successMessage: { items in
                #localized("%lld items moved to trash", items.count)
            }
        }
    }

    func restoreSelectedItems() {
        Task { [weak self] in
            guard let self else { return }
            await performBulkAction { [weak self] items in
                guard let self else { return }
                try await doRestoreSelectedItems(items)
            } successMessage: { items in
                #localized("Restored %lld items", items.count)
            }
        }
    }

    func permanentlyDeleteSelectedItems() {
        Task { [weak self] in
            guard let self else { return }
            await performBulkAction { [weak self] items in
                guard let self else { return }
                let userId = try await userManager.getActiveUserId()
                try await doPermanentlyDeleteSelectedItems(userId: userId, items)
            } successMessage: { items in
                #localized("Permanently deleted %lld items", items.count)
            }
        }
    }

    func disableSelectedAliases() {
        Task { [weak self] in
            guard let self else { return }
            await performBulkAction { [weak self] items in
                guard let self else { return }
                let userId = try await userManager.getActiveUserId()
                try await itemRepository.changeAliasStatus(userId: userId,
                                                           items: items.filter(\.aliasEnabled),
                                                           enabled: false)
            } successMessage: { items in
                #localized("%lld aliases disabled", items.count)
            }
        }
    }

    func enableSelectedAliases() {
        Task { [weak self] in
            guard let self else { return }
            await performBulkAction { [weak self] items in
                guard let self else { return }
                let userId = try await userManager.getActiveUserId()
                try await itemRepository.changeAliasStatus(userId: userId,
                                                           items: items.filter(\.aliasDisabled),
                                                           enabled: true)
            } successMessage: { items in
                #localized("%lld aliases enabled", items.count)
            }
        }
    }

    // swiftlint:enable unhandled_throwing_task

    func askForBulkPermanentDeleteConfirmation() {
        let items = currentSelectedItems.value
        guard !items.isEmpty else {
            assertionFailure("No selected items to permanently delete")
            return
        }
        router.alert(.bulkPermanentDeleteConfirmation(itemCount: items.count))
    }

    func createNewItem(type: ItemContentType) {
        delegate?.itemsTabViewModelWantsToCreateNewItem(type: type)
    }

    func dismiss(banner: InfoBanner) {
        if banner.isInvite {
            return
        }
        banners.removeAll(where: { $0 == banner })
        Task { [weak self] in
            guard let self else { return }
            do {
                let newIds = getAppPreferences().dismissedBannerIds.appending(banner.id)
                try await updateAppPreferences(\.dismissedBannerIds, value: newIds)
            } catch {
                handle(error: error)
            }
        }
    }

    func handleAction(banner: InfoBanner) {
        switch banner {
        case .trial:
            delegate?.itemsTabViewModelWantsToShowTrialDetail()
        case .autofill:
            openAutoFillSettings()
        case .aliases:
            router.navigate(to: .urlPage(urlString: "https://proton.me/support/pass-alias-ios"))
        case let .invite(invites: invites):
            if let firstInvite = invites.first {
                router.present(for: .acceptRejectInvite(firstInvite))
            }
        }
    }

    func presentVaultList() {
        switch vaultsManager.state {
        case .loaded:
            delegate?.itemsTabViewModelWantsToPresentVaultList()
        default:
            logger.error("Can not present vault list. Vaults are not loaded.")
        }
    }

    func viewDetail(of item: any ItemIdentifiable) {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                             itemId: item.itemId) {
                    delegate?.itemsTabViewModelWantsViewDetail(of: itemContent)
                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func handleSelection(_ item: ItemUiModel) {
        if isEditMode {
            selectOrDeselect(item)
        } else {
            viewDetail(of: item)
        }
    }

    func handleThumbnailSelection(_ item: ItemUiModel) {
        if isEditable(item) {
            selectOrDeselect(item)
            isEditMode = true
        }
    }

    func permanentlyDelete() {
        guard let itemToBePermanentlyDeleted else { return }
        itemContextMenuHandler.deletePermanently(itemToBePermanentlyDeleted)
    }
}

private extension ItemsTabViewModel {
    func performBulkAction(_ action: ([ItemUiModel]) async throws -> Void,
                           successMessage: ([ItemUiModel]) -> String) async {
        defer { router.display(element: .globalLoading(shouldShow: false)) }
        do {
            router.display(element: .globalLoading(shouldShow: true))
            let items = currentSelectedItems.value
            try await action(items)
            currentSelectedItems.send([])
            let message = successMessage(items)
            router.display(element: .successMessage(message, config: .dismissAndRefresh))
        } catch {
            handle(error: error)
        }
    }
}

// MARK: - SortTypeListViewModelDelegate

extension ItemsTabViewModel: SortTypeListViewModelDelegate {
    func sortTypeListViewDidSelect(_ sortType: SortType) {
        selectedSortType = sortType
    }
}

// MARK: - SyncEventLoopPullToRefreshDelegate

extension ItemsTabViewModel: SyncEventLoopPullToRefreshDelegate {
    nonisolated func pullToRefreshShouldStopRefreshing() {
        Task { [weak self] in
            guard let self else {
                return
            }
            await stopRefreshing()
        }
    }
}

private extension [UserInvite] {
    var toInfoBanners: InfoBanner {
        .invite(self)
    }
}
