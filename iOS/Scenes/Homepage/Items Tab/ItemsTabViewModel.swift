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
    @Published private(set) var banners: [InfoBanner] = []
    @Published var isEditMode = false
    @Published var shouldShowSyncProgress = false
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
    private let preferences = resolve(\SharedToolingContainer.preferences)
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

    let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    let itemContextMenuHandler = resolve(\SharedServiceContainer.itemContextMenuHandler)

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: ItemsTabViewModelDelegate?
    private var inviteRefreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    /// `PullToRefreshable` conformance
    var pullToRefreshContinuation: CheckedContinuation<Void, Never>?
    let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)

    init() {
        setUp()
    }

    func loadPinnedItems() async {
        guard let symmetricKey = try? symmetricKeyProvider.getSymmetricKey(),
              let newPinnedItems = try? await getAllPinnedItems()
              .compactMap({ try? $0.toItemUiModel(symmetricKey) })
        else { return }
        pinnedItems = Array(newPinnedItems.prefix(5))
    }
}

// MARK: - Private APIs

private extension ItemsTabViewModel {
    func setUp() {
        vaultsManager.attach(to: self, storeIn: &cancellables)

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
        Task { @MainActor [weak self] in
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
            .sink { [weak self] pinnedItems in
                guard let self,
                      let symmetricKey = try? symmetricKeyProvider.getSymmetricKey(),
                      let pinnedItems else {
                    return
                }
                let firstPinnedItems = Array(pinnedItems.prefix(5))
                self.pinnedItems = firstPinnedItems.compactMap { try? $0.toItemUiModel(symmetricKey) }
            }
            .store(in: &cancellables)
    }

    func refreshBanners(_ invites: [UserInvite]? = nil) {
        inviteRefreshTask?.cancel()
        inviteRefreshTask = Task { @MainActor [weak self] in
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
            var banners = [InfoBanner]()
            for banner in InfoBanner.allCases {
                if preferences.dismissedBannerIds.contains(where: { $0 == banner.id }) {
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
            logger.error(error)
            router.display(element: .displayErrorBanner(error))
            return []
        }
    }

    func selectOrDeselect(_ item: any ItemIdentifiable) {
        var items = currentSelectedItems.value
        if items.contains(item) {
            items.removeAll(where: { $0.isEqual(with: item) })
        } else {
            items.append(item)
        }
        currentSelectedItems.send(items)
        if items.isEmpty {
            isEditMode = false
        }
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

    func search(pinnedItems: Bool = false) {
        if pinnedItems {
            router.present(for: .search(.pinned))
        } else {
            router.present(for: .search(.all(vaultsManager.vaultSelection)))
        }
    }

    func isSelected(_ item: any ItemIdentifiable) -> Bool {
        currentSelectedItems.value.contains(item)
    }

    func isEditable(_ item: any ItemIdentifiable) -> Bool {
        canEditItem(vaults: vaultsManager.getAllVaults(), item: item)
    }

    func presentVaultListToMoveSelectedItems() {
        let items = currentSelectedItems.value
        router.present(for: .moveItemsBetweenVaults(.selectedItems(items)))
    }

    func trashSelectedItems() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let items = currentSelectedItems.value
                try await doTrashSelectedItems(items)
                currentSelectedItems.send([])
                let message = #localized("%lld items moved to trash", items.count)
                router.display(element: .infosMessage(message, config: .dismissAndRefresh))
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func restoreSelectedItems() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let items = currentSelectedItems.value
                try await doRestoreSelectedItems(items)
                currentSelectedItems.send([])
                let message = #localized("Restored %lld items", items.count)
                router.display(element: .successMessage(message, config: .dismissAndRefresh))
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func permanentlyDeleteSelectedItems() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let items = currentSelectedItems.value
                try await doPermanentlyDeleteSelectedItems(items)
                currentSelectedItems.send([])
                let message = #localized("Permanently deleted %lld items", items.count)
                router.display(element: .infosMessage(message, config: .dismissAndRefresh))
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

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
        preferences.dismissedBannerIds.append(banner.id)
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
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                if let itemContent = try await self.itemRepository.getItemContent(shareId: item.shareId,
                                                                                  itemId: item.itemId) {
                    self.delegate?.itemsTabViewModelWantsViewDetail(of: itemContent)
                }
            } catch {
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func handleSelection(_ item: any ItemIdentifiable) {
        if isEditMode {
            selectOrDeselect(item)
        } else {
            viewDetail(of: item)
        }
    }

    func handleThumbnailSelection(_ item: any ItemIdentifiable) {
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

private extension [ItemIdentifiable] {
    func contains(_ otherItem: any ItemIdentifiable) -> Bool {
        contains(where: { $0.isEqual(with: otherItem) })
    }
}
