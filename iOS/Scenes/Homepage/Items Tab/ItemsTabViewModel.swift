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
import SwiftUI

protocol ItemsTabViewModelDelegate: AnyObject {
    func itemsTabViewModelWantsToSearch(vaultSelection: VaultSelection)
    func itemsTabViewModelWantsToCreateNewItem(type: ItemContentType)
    func itemsTabViewModelWantsToPresentVaultList()
    func itemsTabViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                     delegate: SortTypeListViewModelDelegate)
    func itemsTabViewModelWantsToShowTrialDetail()
    func itemsTabViewModelWantsViewDetail(of itemContent: ItemContent)
}

final class ItemsTabViewModel: ObservableObject, PullToRefreshable, DeinitPrintable {
    deinit { print(deinitMessage) }

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    @Published private(set) var banners: [InfoBanner] = []
    @Published var shouldShowSyncProgress = false
    @Published var itemToBePermanentlyDeleted: ItemTypeIdentifiable? {
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
}

// MARK: - Private APIs

private extension ItemsTabViewModel {
    func setUp() {
        vaultsManager.attach(to: self, storeIn: &cancellables)
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
    }

    func refreshBanners(_ invites: [UserInvite]? = nil) {
        inviteRefreshTask?.cancel()
        inviteRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            banners.removeAll()
            if let invites, !invites.isEmpty {
                if let newUserInvite = invites.first(where: { $0.fromNewUser }) {
                    router.present(for: .acceptRejectInvite(newUserInvite))
                } else {
                    banners.append(invites.toInfoBanners)
                }
            }
            if banners.isEmpty {
                await fillLocalBanners()
            }
        }
    }

    @MainActor
    func fillLocalBanners() async {
        do {
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
        } catch {
            logger.error(error)
            router.display(element: .displayErrorBanner(error))
        }
    }
}

// MARK: - Public APIs

extension ItemsTabViewModel {
    func search() {
        delegate?.itemsTabViewModelWantsToSearch(vaultSelection: vaultsManager.vaultSelection)
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
            UIApplication.shared.openPasswordSettings()
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

    func presentSortTypeList() {
        delegate?.itemsTabViewModelWantsToPresentSortTypeList(selectedSortType: selectedSortType,
                                                              delegate: self)
    }

    func viewDetail(of item: ItemUiModel) {
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

    func showFilterOptions() {
        router.present(for: .filterItems)
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
    func pullToRefreshShouldStopRefreshing() {
        stopRefreshing()
    }
}

private extension [UserInvite] {
    var toInfoBanners: InfoBanner {
        .invite(self)
    }
}
