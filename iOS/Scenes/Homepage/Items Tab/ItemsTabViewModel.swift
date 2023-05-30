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
import SwiftUI

protocol ItemsTabViewModelDelegate: AnyObject {
    func itemsTabViewModelWantsToShowSpinner()
    func itemsTabViewModelWantsToHideSpinner()
    func itemsTabViewModelWantsToSearch(vaultSelection: VaultSelection)
    func itemsTabViewModelWantsToPresentVaultList(vaultsManager: VaultsManager)
    func itemsTabViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                     delegate: SortTypeListViewModelDelegate)
    func itemsTabViewModelWantsToShowTrialDetail()
    func itemsTabViewModelWantsViewDetail(of itemContent: ItemContent)
    func itemsTabViewModelDidEncounter(error: Error)
}

final class ItemsTabViewModel: ObservableObject, PullToRefreshable, DeinitPrintable {
    deinit { print(deinitMessage) }

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    @Published private(set) var banners: [InfoBanner] = []

    let favIconRepository: FavIconRepositoryProtocol
    let itemContextMenuHandler: ItemContextMenuHandler
    let itemRepository: ItemRepositoryProtocol
    let credentialManager: CredentialManagerProtocol
    let passPlanRepository: PassPlanRepositoryProtocol
    let logger: Logger
    let preferences: Preferences
    let vaultsManager: VaultsManager

    weak var delegate: ItemsTabViewModelDelegate?
    weak var emptyVaultViewModelDelegate: EmptyVaultViewModelDelegate?
    lazy var emptyVaultViewModel = makeEmptyVaultViewModel()

    private var cancellables = Set<AnyCancellable>()

    /// `PullToRefreshable` conformance
    var pullToRefreshContinuation: CheckedContinuation<Void, Never>?
    let syncEventLoop: SyncEventLoop

    init(favIconRepository: FavIconRepositoryProtocol,
         itemContextMenuHandler: ItemContextMenuHandler,
         itemRepository: ItemRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         passPlanRepository: PassPlanRepositoryProtocol,
         logManager: LogManager,
         preferences: Preferences,
         syncEventLoop: SyncEventLoop,
         vaultsManager: VaultsManager) {
        self.favIconRepository = favIconRepository
        self.itemContextMenuHandler = itemContextMenuHandler
        self.itemRepository = itemRepository
        self.credentialManager = credentialManager
        self.passPlanRepository = passPlanRepository
        self.logger = .init(manager: logManager)
        self.preferences = preferences
        self.syncEventLoop = syncEventLoop
        self.vaultsManager = vaultsManager
        self.finalizeInitialization()
        self.refreshBanners()
    }
}

// MARK: - Private APIs
private extension ItemsTabViewModel {
    func finalizeInitialization() {
        vaultsManager.attach(to: self, storeIn: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.refreshBanners()
            }
            .store(in: &cancellables)
    }

    func refreshBanners() {
        Task { @MainActor in
            do {
                var banners: [InfoBanner] = []
                for banner in InfoBanner.allCases {
                    var dismissed = preferences.dismissedBannerIds.contains { $0 == banner.id }

                    switch banner {
                    case .trial:
                        // If not in trial, consider dismissed
                        let plan = try await passPlanRepository.getPlan()
                        switch plan.planType {
                        case .trial:
                            break
                        default:
                            dismissed = true
                        }

                    case .autofill:
                        // We don't show the banner if AutoFill extension is enabled
                        // consider dismissed in this case
                        if await self.credentialManager.isAutoFillEnabled() {
                            dismissed = true
                        }

                    default:
                        break
                    }

                    if !dismissed {
                        banners.append(banner)
                    }
                }

                self.banners = banners
            } catch {
                logger.error(error)
                delegate?.itemsTabViewModelDidEncounter(error: error)
            }
        }
    }

    func makeEmptyVaultViewModel() -> EmptyVaultViewModel {
        let viewModel = EmptyVaultViewModel()
        viewModel.delegate = emptyVaultViewModelDelegate
        return viewModel
    }
}

// MARK: - Public APIs
extension ItemsTabViewModel {
    func search() {
        delegate?.itemsTabViewModelWantsToSearch(vaultSelection: vaultsManager.vaultSelection)
    }

    func dismiss(banner: InfoBanner) {
        banners.removeAll(where: { $0 == banner })
        preferences.dismissedBannerIds.append(banner.id)
    }

    func handleAction(banner: InfoBanner) {
        switch banner {
        case .trial:
            delegate?.itemsTabViewModelWantsToShowTrialDetail()
        case .autofill:
            UIApplication.shared.openPasswordSettings()
        default:
            break
        }
    }

    func presentVaultList() {
        switch vaultsManager.state {
        case .loaded:
            delegate?.itemsTabViewModelWantsToPresentVaultList(vaultsManager: vaultsManager)
        default:
            logger.error("Can not present vault list. Vaults are not loaded.")
        }
    }

    func presentSortTypeList() {
        delegate?.itemsTabViewModelWantsToPresentSortTypeList(selectedSortType: selectedSortType,
                                                              delegate: self)
    }

    func viewDetail(of item: ItemUiModel) {
        Task { @MainActor in
            do {
                if let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                             itemId: item.itemId) {
                    delegate?.itemsTabViewModelWantsViewDetail(of: itemContent)
                }
            } catch {
                delegate?.itemsTabViewModelDidEncounter(error: error)
            }
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
    func pullToRefreshShouldStopRefreshing() {
        stopRefreshing()
    }
}
