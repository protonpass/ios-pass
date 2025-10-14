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
@preconcurrency import CryptoKit
import Entities
import FactoryKit
import Macro
import SwiftUI

@MainActor
protocol ItemsTabViewModelDelegate: AnyObject {
    func itemsTabViewModelWantsToCreateNewItem(type: ItemContentType)
    func itemsTabViewModelWantsToPresentVaultList()
    func itemsTabViewModelWantsViewDetail(of itemContent: ItemContent)
}

@MainActor
final class ItemsTabViewModel: ObservableObject, PullToRefreshable, DeinitPrintable {
    deinit { print(deinitMessage) }

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    @AppStorage(Constants.filterTypeKey, store: kSharedUserDefaults)
    private(set) var filterOption = ItemTypeFilterOption.all

    @Published private(set) var pinnedItems: [ItemUiModel]?
    @Published private(set) var showingUpgradeAppBanner = false
    @Published private(set) var banners: [InfoBanner] = []
    @Published private(set) var shouldShowSyncProgress = false
    @Published var isEditMode = false
    @Published var itemToBePermanentlyDeleted: (any ItemTypeIdentifiable)?
    @Published private(set) var sectionedItems: FetchableObject<[SectionedItemUiModel]> = .fetching
    @Published private var organization: Organization?
    @Published private(set) var refreshSearchResult = false
    @Published private(set) var showPromoBadge = false

    let currentSelectedItems = resolve(\DataStreamContainer.currentSelectedItems)
    @LazyInjected(\SharedServiceContainer.appContentManager) var appContentManager

    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)
    private let getPendingUserInvitations = resolve(\UseCasesContainer.getPendingUserInvitations)
    private let doTrashSelectedItems = resolve(\UseCasesContainer.trashSelectedItems)
    private let doRestoreSelectedItems = resolve(\UseCasesContainer.restoreSelectedItems)
    private let doPermanentlyDeleteSelectedItems = resolve(\UseCasesContainer.permanentlyDeleteSelectedItems)
    private let getAllPinnedItems = resolve(\UseCasesContainer.getAllPinnedItems)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)
    private let canEditItem = resolve(\SharedUseCasesContainer.canEditItem)
    private let shouldDisplayUpgradeAppBanner = resolve(\UseCasesContainer.shouldDisplayUpgradeAppBanner)
    private let pinItems = resolve(\SharedUseCasesContainer.pinItems)
    private let unpinItems = resolve(\SharedUseCasesContainer.unpinItems)
    @LazyInjected(\SharedServiceContainer.inAppNotificationManager) var inAppNotificationManager

    let itemContextMenuHandler = resolve(\SharedServiceContainer.itemContextMenuHandler)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRepositoryContainer.organizationRepository)
    private var organizationRepository

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let itemTypeSelection = resolve(\DataStreamContainer.itemTypeSelection)

    weak var delegate: (any ItemsTabViewModelDelegate)?
    private var sortTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()

    /// `PullToRefreshable` conformance
    var pullToRefreshContinuation: CheckedContinuation<Void, Never>?
    let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)

    var noVaults: Bool {
        if case let .loaded(data) = appContentManager.state,
           data.isEmpty, organization?.settings?.vaultCreateMode == .adminsOnly {
            return true
        }
        return false
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
                try await appContentManager.refresh(userId: userId)
                refreshSearchResult.toggle()
            } catch {
                handle(error: error)
            }
        }
    }

    func continueFullSyncIfNeeded() {
        Task { [weak self] in
            guard let self else { return }
            if let userId = appContentManager.incompleteFullSyncUserId {
                router.present(for: .fullSync)
                await appContentManager.fullSync(userId: userId)
            }
        }
    }
}

// MARK: - Private APIs

private extension ItemsTabViewModel {
    // swiftlint:disable:next cyclomatic_complexity
    func setUp() {
        appContentManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .loading:
                    sectionedItems = .fetching
                case .loaded:
                    filterAndSortItems()
                case let .error(error):
                    sectionedItems = .error(error)
                }
            }
            .store(in: &cancellables)

        appContentManager.$vaultSelection
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                filterAndSortItems()
            }
            .store(in: &cancellables)

        appContentManager.vaultSyncEventStream
            .subscribe(on: DispatchQueue.main)
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
                refreshBanners(getPendingUserInvitations().value)
            }
            .store(in: &cancellables)

        // Show the progress if after 5 seconds after logging in and items are not yet loaded
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(seconds: 5)

            if await loginMethod.isManualLogIn(),
               case .loading = appContentManager.state {
                shouldShowSyncProgress = true
            }
        }

        getAllPinnedItems()
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .compactMap(\.self)
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

        itemTypeSelection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] type in
                guard let self else { return }
                appContentManager.select(.all, filterOption: .precise(type))
                router.display(element: .infosMessage(type.filterMessage))
            }
            .store(in: &cancellables)

        inAppNotificationManager.notificationToDisplayPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self else { return }
                showPromoBadge = notification?.displayType == .promo
            }
            .store(in: &cancellables)
    }

    func refreshBanners(_ invites: [UserInvite]? = nil) {
        var banners = [InfoBanner]()
        if let invites, !invites.isEmpty {
            if let newUserInvite = invites.first(where: { $0.fromNewUser }) {
                router.present(for: .acceptRejectInvite(newUserInvite))
            } else {
                banners.append(invites.toInfoBanners)
            }
        }
        self.banners = banners
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
    func filterAndSortItems(sortType: SortType? = nil) {
        let sortType = sortType ?? selectedSortType
        sortTask?.cancel()
        sortTask = Task { [weak self] in
            guard let self else { return }
            await filterAndSortItemsAsync(sortType: sortType)

            do {
                let userId = try await userManager.getActiveUserId()
                if accessRepository.access.value?.access.plan.isBusinessUser == true {
                    organization = try await organizationRepository.getOrganization(userId: userId)
                }
            } catch {
                handle(error: error)
            }
        }
    }

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
        canEditItem(vaults: appContentManager.getAllShares(), item: item)
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

    func hasSharedItems() -> Bool {
        currentSelectedItems.value.contains { $0.shared }
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

    func showNotification() {
        inAppNotificationManager.updatePromoMinimizationState(shouldBeMinimized: false)
    }

    // swiftlint:enable unhandled_throwing_task

    func askForBulkPermanentDeleteConfirmation() {
        let items = currentSelectedItems.value
        guard !items.isEmpty else {
            assertionFailure("No selected items to permanently delete")
            return
        }
        let aliasCount = items.count { $0.isAlias }
        router.alert(.bulkPermanentDeleteConfirmation(itemCount: items.count,
                                                      aliasCount: aliasCount))
    }

    func createNewItem(type: ItemContentType) {
        delegate?.itemsTabViewModelWantsToCreateNewItem(type: type)
    }

    func handleAction(banner: InfoBanner) {
        switch banner {
        case let .invite(invites: invites):
            if let firstInvite = invites.first {
                router.present(for: .acceptRejectInvite(firstInvite))
            }
        }
    }

    func presentVaultList() {
        switch appContentManager.state {
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
        let shares = appContentManager.getAllShares()
        let isMultiEditable = shares.first { $0.id == item.shareId }?.canMutiSelectEdit ?? false

        if isMultiEditable {
            selectOrDeselect(item)
            isEditMode = true
        }
    }

    func disableAlias() {
        guard let itemToBePermanentlyDeleted else { return }
        itemContextMenuHandler.disableAlias(itemToBePermanentlyDeleted)
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

    nonisolated func filterAndSortItemsAsync(sortType: SortType) async {
        do {
            let filteredItems = await appContentManager.getFilteredItems()

            let sectionedItems: [SectionedItemUiModel]
            switch await selectedSortType {
            case .mostRecent:
                let sortedResult = try filteredItems.mostRecentSortResult()
                sectionedItems = sortedResult.buckets.compactMap { bucket in
                    guard !bucket.items.isEmpty else { return nil }
                    return .init(id: bucket.id,
                                 sectionTitle: bucket.type.title,
                                 items: bucket.items)
                }

            case .alphabeticalAsc, .alphabeticalDesc:
                let sortedResult = try filteredItems.alphabeticalSortResult(direction: sortType.sortDirection)
                sectionedItems = sortedResult.buckets.compactMap { bucket in
                    guard !bucket.items.isEmpty else { return nil }
                    return .init(id: bucket.letter.character,
                                 sectionTitle: bucket.letter.character,
                                 items: bucket.items)
                }

            case .newestToOldest, .oldestToNewest:
                let sortedResult = try filteredItems.monthYearSortResult(direction: sortType.sortDirection)
                sectionedItems = sortedResult.buckets.compactMap { bucket in
                    guard !bucket.items.isEmpty else { return nil }
                    return .init(id: bucket.monthYear.relativeString,
                                 sectionTitle: bucket.monthYear.relativeString,
                                 items: bucket.items)
                }
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.sectionedItems = .fetched(sectionedItems)
            }
        } catch {
            if error is CancellationError {
                #if DEBUG
                print("Cancelled \(#function)")
                #endif
                return
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                sectionedItems = .error(error)
            }
        }
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
