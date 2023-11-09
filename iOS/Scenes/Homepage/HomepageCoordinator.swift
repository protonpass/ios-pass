//
// HomepageCoordinator.swift
// Proton Pass - Created on 06/03/2023.
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

// swiftlint:disable file_length
import Client
import Combine
import Core
import CoreData
import CryptoKit
import DesignSystem
import Entities
import Factory
import Macro
import MBProgressHUD
import ProtonCoreAccountDeletion
import ProtonCoreFeatureSwitch
import ProtonCoreLogin
import ProtonCoreServices
import ProtonCoreUIFoundations
import Screens
import StoreKit
import SwiftUI
import UIKit

private let kRefreshInvitationsTaskLabel = "RefreshInvitationsTask"

protocol HomepageCoordinatorDelegate: AnyObject {
    func homepageCoordinatorWantsToLogOut()
    func homepageCoordinatorDidFailLocallyAuthenticating()
}

final class HomepageCoordinator: Coordinator, DeinitPrintable {
    deinit { print(deinitMessage) }

    // Injected & self-initialized properties
    private let eventLoop = resolve(\SharedServiceContainer.syncEventLoop)
    private let itemContextMenuHandler = resolve(\SharedServiceContainer.itemContextMenuHandler)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let paymentsManager = resolve(\ServiceContainer.paymentManager)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let telemetryEventRepository = resolve(\SharedRepositoryContainer.telemetryEventRepository)
    private let urlOpener = UrlOpener()
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let refreshInvitations = resolve(\UseCasesContainer.refreshInvitations)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)

    // Lazily initialised properties
    @LazyInjected(\SharedServiceContainer.clipboardManager) private var clipboardManager
    @LazyInjected(\SharedViewContainer.bannerManager) private var bannerManager
    @LazyInjected(\UseCasesContainer.updateItemsWithLastUsedTime) private var updateItemsWithLastUsedTime
    @LazyInjected(\SharedToolingContainer.apiManager) private var apiManager

    // Use cases
    private let refreshFeatureFlags = resolve(\UseCasesContainer.refreshFeatureFlags)
    private let addTelemetryEvent = resolve(\SharedUseCasesContainer.addTelemetryEvent)

    // References
    private weak var profileTabViewModel: ProfileTabViewModel?
    private weak var searchViewModel: SearchViewModel?
    private var itemDetailCoordinator: ItemDetailCoordinator?
    private var createEditItemCoordinator: CreateEditItemCoordinator?
    private var customCoordinator: CustomCoordinator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Navigation Router

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: HomepageCoordinatorDelegate?
    weak var homepageTabDelegete: HomepageTabDelegete?

    override init() {
        super.init()
        SharedViewContainer.shared.register(rootViewController: rootViewController)
        setUpRouting()
        finalizeInitialization()
        vaultsManager.refresh()
        start()
        eventLoop.start()
        refreshAccess()
        refreshFeatureFlags()
        sendAllEventsIfApplicable()
    }
}

// MARK: - Private APIs & Setup & Utils

private extension HomepageCoordinator {
    /// Some properties are dependant on other propeties which are in turn not initialized
    /// before the Coordinator is fully initialized. This method is to resolve these dependencies.
    func finalizeInitialization() {
        eventLoop.delegate = self
        itemContextMenuHandler.delegate = self
        urlOpener.rootViewController = rootViewController

        eventLoop.addAdditionalTask(.init(label: kRefreshInvitationsTaskLabel,
                                          task: refreshInvitations.callAsFunction))

        accessRepository.didUpdateToNewPlan
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                logger.trace("Found new plan, refreshing credential database")
                homepageTabDelegete?.homepageTabShouldRefreshTabIcons()
                profileTabViewModel?.refreshPlan()
            }
            .store(in: &cancellables)

        preferences.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                rootViewController.setUserInterfaceStyle(preferences
                    .theme.userInterfaceStyle)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                eventLoop.stop()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                logger.info("App goes back to foreground")
                apiManager.startCredentialUpdate()
            }
            .store(in: &cancellables)

        apiManager.credentialFinishedUpdating
            .removeDuplicates()
            .sink { [weak self] finishedUpdating in
                guard let self, finishedUpdating else { return }
                refresh()
                sendAllEventsIfApplicable()
                eventLoop.start()
                eventLoop.forceSync()
                refreshAccess()
                refreshItems()
                refreshFeatureFlags()
            }
            .store(in: &cancellables)
    }

    func start() {
        let itemsTabViewModel = ItemsTabViewModel()
        itemsTabViewModel.delegate = self

        let profileTabViewModel = ProfileTabViewModel(childCoordinatorDelegate: self)
        profileTabViewModel.delegate = self
        self.profileTabViewModel = profileTabViewModel

        let placeholderView = ItemDetailPlaceholderView { [weak self] in
            guard let self else { return }
            popTopViewController(animated: true)
        }

        let homeView = HomepageTabbarView(itemsTabViewModel: itemsTabViewModel,
                                          profileTabViewModel: profileTabViewModel,
                                          homepageCoordinator: self,
                                          delegate: self)
            .ignoresSafeArea(edges: [.top, .bottom])
            .localAuthentication(delayed: false,
                                 onAuth: { [weak self] in
                                     guard let self else { return }
                                     dismissAllViewControllers(animated: false)
                                     hideSecondaryView()
                                 },
                                 onSuccess: { [weak self] in
                                     guard let self else { return }
                                     showSecondaryView()
                                     logger.info("Local authentication succesful")
                                 },
                                 onFailure: { [weak self] in
                                     guard let self else { return }
                                     logger.error("Failed to locally authenticate. Logging out.")
                                     delegate?.homepageCoordinatorDidFailLocallyAuthenticating()
                                 })

        start(with: homeView, secondaryView: placeholderView)
        rootViewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
    }

    func refreshAccess() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await accessRepository.refreshAccess()
            } catch {
                logger.error(error)
            }
        }
    }

    func refreshItems() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await updateItemsWithLastUsedTime()
            } catch {
                logger.error(error)
            }
        }
    }

    func refresh() {
        vaultsManager.refresh()
        searchViewModel?.refreshResults()
        itemDetailCoordinator?.refresh()
        createEditItemCoordinator?.refresh()
    }

    func addNewEvent(type: TelemetryEventType) {
        addTelemetryEvent(with: type)
    }

    func sendAllEventsIfApplicable() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await telemetryEventRepository.sendAllEventsIfApplicable()
            } catch {
                logger.error(error)
            }
        }
    }

    func increaseCreatedItemsCountAndAskForReviewIfNecessary() {
        preferences.createdItemsCount += 1
        // Only ask for reviews when not in macOS because macOS doesn't respect 3 times per year limit
        if !ProcessInfo.processInfo.isiOSAppOnMac,
           preferences.createdItemsCount >= 10,
           let windowScene = rootViewController.view.window?.windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

// MARK: - Navigation & Routing & View presentation

private extension HomepageCoordinator {
    // MARK: - Router setup

    // swiftlint:disable:next cyclomatic_complexity
    func setUpRouting() {
        router
            .newPresentationDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .urlPage(urlString: url):
                    urlOpener.open(urlString: url)
                case .openSettings:
                    UIApplication.shared.openAppSettings()
                }
            }
            .store(in: &cancellables)

        router
            .newSheetDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .sharingFlow(dismissal):
                    presentSharingFlow(dismissal: dismissal)
                case let .manageShareVault(vault, dismissal):
                    presentManageShareVault(with: vault, dismissal: dismissal)
                case .filterItems:
                    presentItemFilterOptions()
                case let .acceptRejectInvite(invite):
                    presentAcceptRejectInvite(with: invite)
                case .upgradeFlow:
                    startUpgradeFlow()
                case .upselling:
                    startUpsellingFlow()
                case let .vaultCreateEdit(vault: vault):
                    createEditVaultView(vault: vault)
                case let .logView(module: module):
                    presentLogsView(for: module)
                case let .suffixView(suffixSelection):
                    presentSuffixSelectionView(selection: suffixSelection)
                case let .mailboxView(mailboxSelection, mode):
                    presentMailboxSelectionView(selection: mailboxSelection,
                                                mode: .createAliasLite,
                                                titleMode: mode)
                case .autoFillInstructions:
                    present(AutoFillInstructionsView())
                case let .moveItemsBetweenVaults(currentVault, itemToMove):
                    itemMoveBetweenVault(currentVault: currentVault, itemToMove: itemToMove)
                case .fullSync:
                    present(FullSyncProgressView(mode: .fullSync), dismissible: false)
                case let .shareVaultFromItemDetail(vault, itemContent):
                    if vault.vault.shared {
                        presentManageShareVault(with: vault.vault, dismissal: .none)
                    } else {
                        presentShareOrCreateNewVaultView(for: vault, itemContent: itemContent)
                    }
                case let .customizeNewVault(vault, itemContent):
                    presentCreateEditVaultView(mode: .editNewVault(vault, itemContent))
                case .vaultSelection:
                    createEditItemViewModelWantsToChangeVault()
                }
            }
            .store(in: &cancellables)

        router
            .globalElementDisplay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .globalLoading(shouldShow):
                    if shouldShow {
                        showLoadingHud()
                    } else {
                        hideLoadingHud()
                    }
                case let .displayErrorBanner(errorLocalized):
                    bannerManager.displayTopErrorMessage(errorLocalized)
                case let .successMessage(message, config):
                    displaySuccessBanner(with: message, and: config)
                case let .infosMessage(message, config):
                    displayInfoBanner(with: message, and: config)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - UI view presenting functions

    func presentSharingFlow(dismissal: SheetDismissal) {
        let completion: () -> Void = { [weak self] in
            guard let self else { return }
            present(UserEmailView())
        }

        switch dismissal {
        case .none:
            completion()
        case .topMost:
            dismissTopMostViewController(animated: true, completion: completion)
        case .all:
            dismissAllViewControllers(animated: true, completion: completion)
        }
    }

    func createEditVaultView(vault: Vault?) {
        if let vault {
            presentCreateEditVaultView(mode: .editExistingVault(vault))
        } else {
            presentCreateEditVaultView(mode: .create)
        }
    }

    func presentManageShareVault(with vault: Vault, dismissal: SheetDismissal) {
        let manageShareVaultView = ManageSharedVaultView(viewModel: ManageSharedVaultViewModel(vault: vault))

        let completion: () -> Void = { [weak self] in
            guard let self else {
                return
            }
            if let host = rootViewController
                .topMostViewController as? UIHostingController<ManageSharedVaultView> {
                /// Updating share data circumventing the onAppear not being called after a sheet presentation
                host.rootView.refresh()
                return
            }
            present(manageShareVaultView)
        }

        switch dismissal {
        case .none:
            present(manageShareVaultView)
        case .topMost:
            dismissTopMostViewController(animated: true, completion: completion)
        case .all:
            dismissAllViewControllers(animated: true, completion: completion)
        }
    }

    func presentItemFilterOptions() {
        let view = ItemTypeFilterOptionsView()
        let viewController = UIHostingController(rootView: view)
        let height = ItemTypeFilterOptionsView.rowHeight * CGFloat(ItemTypeFilterOption.allCases.count) + 70
        viewController.setDetentType(.customAndLarge(height),
                                     parentViewController: rootViewController)
        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentAcceptRejectInvite(with invite: UserInvite) {
        let view = AcceptRejectInviteView(viewModel: AcceptRejectInviteViewModel(invite: invite))

        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.medium,
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentLogsView(for module: PassModule) {
        let viewModel = LogsViewModel(module: module)
        viewModel.delegate = self
        let view = LogsView(viewModel: viewModel)
        present(view)
    }

    func presentItemDetailView(for itemContent: ItemContent, asSheet: Bool) {
        let coordinator = ItemDetailCoordinator(itemDetailViewModelDelegate: self)
        coordinator.delegate = self
        coordinator.showDetail(for: itemContent, asSheet: asSheet)
        itemDetailCoordinator = coordinator
        addNewEvent(type: .read(itemContent.type))
    }

    func presentEditItemView(for itemContent: ItemContent) {
        do {
            let coordinator = makeCreateEditItemCoordinator()
            try coordinator.presentEditItemView(for: itemContent)
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
        }
    }

    func presentItemTypeListView() {
        let viewModel = ItemTypeListViewModel()
        viewModel.delegate = self
        let view = ItemTypeListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.medium, parentViewController: rootViewController)
        present(viewController)
    }

    func presentCreateItemView(for itemType: ItemType) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                let coordinator = makeCreateEditItemCoordinator()
                try await coordinator.presentCreateItemView(for: itemType)
            } catch {
                logger.error(error)
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }

    func presentMailboxSelectionView(selection: MailboxSelection,
                                     mode: MailboxSelectionViewModel.Mode,
                                     titleMode: MailboxSection.Mode) {
        let viewModel = MailboxSelectionViewModel(mailboxSelection: selection,
                                                  mode: mode,
                                                  titleMode: titleMode)
        let view = MailboxSelectionView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * selection.mailboxes.count + 150
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentSuffixSelectionView(selection: SuffixSelection) {
        let viewModel = SuffixSelectionViewModel(suffixSelection: selection)
        let view = SuffixSelectionView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * selection.suffixes.count + 100
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentSortTypeList(selectedSortType: SortType,
                             delegate: SortTypeListViewModelDelegate) {
        let viewModel = SortTypeListViewModel(sortType: selectedSortType)
        viewModel.delegate = delegate
        let view = SortTypeListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * SortType.allCases.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentCreateEditVaultView(mode: VaultMode) {
        let viewModel = CreateEditVaultViewModel(mode: mode)
        viewModel.delegate = self
        let view = CreateEditVaultView(viewModel: viewModel)
        present(view)
    }

    func presentShareOrCreateNewVaultView(for vault: VaultListUiModel, itemContent: ItemContent) {
        let view = ShareOrCreateNewVaultView(vault: vault, itemContent: itemContent)
        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.custom(310),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func startUpgradeFlow() {
        dismissAllViewControllers(animated: true) { [weak self] in
            guard let self else { return }
            paymentsManager.upgradeSubscription { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(inAppPurchasePlan):
                    if inAppPurchasePlan != nil {
                        refreshAccess()
                    } else {
                        logger.debug("Payment is done but no plan is purchased")
                    }
                case let .failure(error):
                    bannerManager.displayTopErrorMessage(error)
                }
            }
        }
    }

    func startUpsellingFlow() {
        dismissAllViewControllers(animated: true) { [weak self] in
            guard let self else { return }
            let view = UpsellingView { [weak self] in
                guard let self else {
                    return
                }
                startUpgradeFlow()
            }
            let viewController = UIHostingController(rootView: view)

            viewController.sheetPresentationController?.prefersGrabberVisible = false
            present(viewController)
        }
    }

    func displaySuccessBanner(with message: String?, and config: NavigationConfiguration?) {
        parseNavigationConfig(config: config)

        guard let message else { return }

        if let config, config.dismissBeforeShowing {
            dismissTopMostViewController(animated: true) { [weak self] in
                guard let self else { return }
                bannerManager.displayBottomSuccessMessage(message)
            }
        } else {
            bannerManager.displayBottomSuccessMessage(message)
        }
    }

    func displayInfoBanner(with message: String?, and config: NavigationConfiguration?) {
        parseNavigationConfig(config: config)

        guard let message else { return }

        if let config, config.dismissBeforeShowing {
            dismissTopMostViewController(animated: true) { [weak self] in
                guard let self else { return }
                bannerManager.displayBottomInfoMessage(message)
            }
        } else {
            bannerManager.displayBottomInfoMessage(message)
        }
    }

    func itemMoveBetweenVault(currentVault: Vault, itemToMove: ItemContent?) {
        let allVaults = vaultsManager.getAllEditableVaultContents()
        guard !allVaults.isEmpty else {
            return
        }
        let viewModel = MoveVaultListViewModel(allVaults: allVaults,
                                               currentVault: currentVault,
                                               itemContent: itemToMove)
        let view = MoveVaultListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = 66 * allVaults.count + 180
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    // MARK: - UI Helper presentation functions

    func shouldShowAsSheet() -> Bool {
        !UIDevice.current.isIpad || (UIDevice.current.isIpad && isCollapsed())
    }

    func showView(view: some View, asSheet: Bool) {
        if asSheet {
            present(view)
        } else {
            push(view)
        }
    }

    func adaptivelyDismissCurrentDetailView() {
        // Dismiss differently because show differently
        if rootViewController != topMostViewController {
            dismissTopMostViewController()
        } else {
            popTopViewController(animated: true)
        }
    }

    func present(_ view: some View, animated: Bool = true, dismissible: Bool = true) {
        present(UIHostingController(rootView: view),
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                animated: animated,
                dismissible: dismissible)
    }

    func present(_ viewController: UIViewController, animated: Bool = true, dismissible: Bool = true) {
        present(viewController,
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                animated: animated,
                dismissible: dismissible)
    }
}

// MARK: - Coordinators

private extension HomepageCoordinator {
    func makeCreateEditItemCoordinator() -> CreateEditItemCoordinator {
        let coordinator = CreateEditItemCoordinator(createEditItemDelegates: self)
        coordinator.delegate = self
        createEditItemCoordinator = coordinator
        return coordinator
    }
}

// MARK: - Public APIs

extension HomepageCoordinator {
    func onboardIfNecessary() {
        Task { @MainActor [weak self] in
            guard let self,
                  await loginMethod.isManualLogIn() else { return }
            if let access = try? await accessRepository.getAccess(),
               access.waitingNewUserInvites > 0 {
                // New user just registered after an invitation
                presentAwaitAccessConfirmationView()
            } else {
                presentOnboardView(forced: false)
            }
        }
    }
}

// MARK: - Onboard

private extension HomepageCoordinator {
    func presentAwaitAccessConfirmationView() {
        let view = AwaitAccessConfirmationView { [weak self] in
            guard let self else { return }
            dismissAllViewControllers(animated: true) { [weak self] in
                guard let self else { return }
                presentOnboardView(forced: true)
            }
        }
        .theme(preferences.theme)
        let vc = UIHostingController(rootView: view)
        vc.modalPresentationStyle = UIDevice.current.isIpad ? .formSheet : .fullScreen
        vc.isModalInPresentation = true
        topMostViewController.present(vc, animated: true)
    }

    func presentOnboardView(forced: Bool) {
        guard forced || !preferences.onboarded else { return }
        let vc = UIHostingController(rootView: OnboardingView())
        vc.modalPresentationStyle = UIDevice.current.isIpad ? .formSheet : .fullScreen
        vc.isModalInPresentation = true
        topMostViewController.present(vc, animated: true)
    }
}

// MARK: - HomepageTabBarControllerDelegate

extension HomepageCoordinator: HomepageTabBarControllerDelegate {
    func homepageTabBarControllerDidSelectItemsTab() {
        if !isCollapsed() {
            let placeholderView = ItemDetailPlaceholderView { [weak self] in
                guard let self else { return }
                popTopViewController(animated: true)
            }
            push(placeholderView)
        }
    }

    func homepageTabBarControllerWantToCreateNewItem() {
        presentItemTypeListView()
    }

    func homepageTabBarControllerDidSelectProfileTab() {
        if !isCollapsed() {
            profileTabViewModelWantsToShowAccountMenu()
        }
    }
}

// MARK: - ChildCoordinatorDelegate

extension HomepageCoordinator: ChildCoordinatorDelegate {
    func childCoordinatorWantsToPresent(viewController: UIViewController,
                                        viewOption: ChildCoordinatorViewOption,
                                        presentationOption: ChildCoordinatorPresentationOption) {
        switch viewOption {
        case .sheet:
            // Nothing special to set up
            break

        case .sheetWithGrabber:
            viewController.sheetPresentationController?.prefersGrabberVisible = true

        case let .customSheet(height):
            viewController.setDetentType(.custom(CGFloat(height)),
                                         parentViewController: rootViewController)

        case let .customSheetWithGrabber(height):
            viewController.setDetentType(.custom(CGFloat(height)),
                                         parentViewController: rootViewController)
            viewController.sheetPresentationController?.prefersGrabberVisible = true

        case .fullScreen:
            viewController.modalPresentationStyle = .fullScreen
        }

        switch presentationOption {
        case .none:
            present(viewController)

        case .dismissTopViewController:
            dismissTopMostViewController { [weak self] in
                guard let self else { return }
                present(viewController)
            }

        case .dismissAllViewControllers:
            dismissAllViewControllers { [weak self] in
                guard let self else { return }
                present(viewController)
            }
        }
    }

    func childCoordinatorWantsToDisplayBanner(bannerOption: ChildCoordinatorBannerOption,
                                              presentationOption: ChildCoordinatorPresentationOption) {
        let display: () -> Void = { [weak self] in
            guard let self else { return }
            switch bannerOption {
            case let .info(message):
                bannerManager.displayBottomInfoMessage(message)
            case let .success(message):
                bannerManager.displayBottomSuccessMessage(message)
            case let .error(message):
                bannerManager.displayTopErrorMessage(message)
            }
        }
        switch presentationOption {
        case .none:
            display()
        case .dismissTopViewController:
            dismissTopMostViewController(animated: true, completion: display)
        case .dismissAllViewControllers:
            dismissAllViewControllers(animated: true, completion: display)
        }
    }

    func childCoordinatorWantsToDismissTopViewController() {
        dismissTopMostViewController()
    }

    func childCoordinatorDidFailLocalAuthentication() {
        delegate?.homepageCoordinatorDidFailLocallyAuthenticating()
    }
}

// MARK: - ItemTypeListViewModelDelegate

extension HomepageCoordinator: ItemTypeListViewModelDelegate {
    func itemTypeListViewModelDidSelect(type: ItemType) {
        dismissTopMostViewController { [weak self] in
            guard let self else { return }
            presentCreateItemView(for: type)
        }
    }
}

// MARK: - ItemsTabViewModelDelegate

extension HomepageCoordinator: ItemsTabViewModelDelegate {
    func itemsTabViewModelWantsToSearch(vaultSelection: VaultSelection) {
        let viewModel = SearchViewModel(vaultSelection: vaultSelection)
        viewModel.delegate = self
        searchViewModel = viewModel
        let view = SearchView(viewModel: viewModel)
        present(view)
        addNewEvent(type: .searchTriggered)
    }

    func itemsTabViewModelWantsToCreateNewItem(type: ItemContentType) {
        presentCreateItemView(for: type.type)
    }

    func itemsTabViewModelWantsToPresentVaultList() {
        let viewModel = EditableVaultListViewModel()
        viewModel.delegate = self
        let view = EditableVaultListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        // Num of vaults + all items + trash + create vault button
        let rowHeight = 74
        let customHeight = rowHeight * vaultsManager.getVaultCount() + rowHeight + rowHeight + 120
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func itemsTabViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                     delegate: SortTypeListViewModelDelegate) {
        presentSortTypeList(selectedSortType: selectedSortType, delegate: delegate)
    }

    func itemsTabViewModelWantsToShowTrialDetail() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.hideLoadingHud() }
            do {
                self.showLoadingHud()

                let plan = try await self.accessRepository.getPlan()
                guard let trialEnd = plan.trialEnd else { return }
                let trialEndDate = Date(timeIntervalSince1970: TimeInterval(trialEnd))
                let daysLeft = Calendar.current.numberOfDaysBetween(trialEndDate, and: .now)

                self.hideLoadingHud()

                let view = TrialDetailView(daysLeft: abs(daysLeft),
                                           onUpgrade: { self.startUpgradeFlow() },
                                           onLearnMore: { self.urlOpener.open(urlString: ProtonLink.trialPeriod) })
                self.present(view)
            } catch {
                self.logger.error(error)
                self.bannerManager.displayTopErrorMessage(error)
            }
        }
    }

    func itemsTabViewModelWantsViewDetail(of itemContent: Client.ItemContent) {
        presentItemDetailView(for: itemContent, asSheet: shouldShowAsSheet())
    }
}

// MARK: - ItemDetailCoordinatorDelegate

extension HomepageCoordinator: ItemDetailCoordinatorDelegate {
    func itemDetailCoordinatorWantsToPresent(view: any View, asSheet: Bool) {
        if asSheet {
            present(view)
        } else {
            push(view)
        }
    }
}

// MARK: - CreateEditItemCoordinatorDelegate

extension HomepageCoordinator: CreateEditItemCoordinatorDelegate {
    func createEditItemCoordinatorWantsToPresent(view: any View, dismissable: Bool) {
        present(view, dismissible: dismissable)
    }
}

// MARK: - ProfileTabViewModelDelegate

extension HomepageCoordinator: ProfileTabViewModelDelegate {
    func profileTabViewModelWantsToShowAccountMenu() {
        let asSheet = shouldShowAsSheet()
        let viewModel = AccountViewModel(isShownAsSheet: asSheet)
        viewModel.delegate = self
        let view = AccountView(viewModel: viewModel)
        showView(view: view, asSheet: asSheet)
    }

    func profileTabViewModelWantsToShowSettingsMenu() {
        let asSheet = shouldShowAsSheet()
        let viewModel = SettingsViewModel(isShownAsSheet: asSheet)
        viewModel.delegate = self
        let view = SettingsView(viewModel: viewModel)
        showView(view: view, asSheet: asSheet)
    }

    func profileTabViewModelWantsToShowFeedback() {
        let view = FeedbackChannelsView { [weak self] selectedChannel in
            guard let self else { return }
            switch selectedChannel {
            case .bugReport:
                dismissTopMostViewController(animated: true) { [weak self] in
                    guard let self else { return }
                    presentBugReportView()
                }
            default:
                if let urlString = selectedChannel.urlString {
                    urlOpener.open(urlString: urlString)
                }
            }
        }

        let viewController = UIHostingController(rootView: view)
        let customHeight = 52 * FeedbackChannel.allCases.count + 80
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentBugReportView() {
        let errorHandler: (Error) -> Void = { [weak self] error in
            guard let self else { return }
            bannerManager.displayTopErrorMessage(error)
        }
        let successHandler: () -> Void = { [weak self] in
            guard let self else { return }
            dismissTopMostViewController { [weak self] in
                guard let self else { return }
                bannerManager.displayBottomSuccessMessage(#localized("Report successfully sent"))
            }
        }
        let view = BugReportView(onError: errorHandler, onSuccess: successHandler)
        present(view)
    }

    func profileTabViewModelWantsToQaFeatures() {
        let view = QAFeaturesView()
        present(view)
    }
}

// MARK: - AccountViewModelDelegate

extension HomepageCoordinator: AccountViewModelDelegate {
    func accountViewModelWantsToGoBack() {
        adaptivelyDismissCurrentDetailView()
    }

    func accountViewModelWantsToSignOut() {
        eventLoop.stop()
        delegate?.homepageCoordinatorWantsToLogOut()
    }

    func accountViewModelWantsToDeleteAccount() {
        let apiManager = resolve(\SharedToolingContainer.apiManager)
        let accountDeletion = AccountDeletionService(api: apiManager.apiService)
        let view = topMostViewController.view
        showLoadingHud(view)
        accountDeletion.initiateAccountDeletionProcess(over: topMostViewController,
                                                       performAfterShowingAccountDeletionScreen: { [weak self] in
                                                           guard let self else { return }
                                                           hideLoadingHud(view)
                                                       },
                                                       completion: { [weak self] result in
                                                           guard let self else { return }
                                                           hideLoadingHud(view)
                                                           DispatchQueue.main.async { [weak self] in
                                                               guard let self else { return }
                                                               switch result {
                                                               case .success:
                                                                   logger.trace("Account deletion successful")
                                                                   accountViewModelWantsToSignOut()
                                                               case .failure(AccountDeletionError.closedByUser):
                                                                   logger
                                                                       .trace("Accpunt deletion form closed by user")
                                                               case let .failure(error):
                                                                   logger.error(error)
                                                                   bannerManager
                                                                       .displayTopErrorMessage(error
                                                                           .userFacingMessageInAccountDeletion)
                                                               }
                                                           }
                                                       })
    }
}

// MARK: - SettingsViewModelDelegate

extension HomepageCoordinator: SettingsViewModelDelegate {
    func settingsViewModelWantsToGoBack() {
        adaptivelyDismissCurrentDetailView()
    }

    func settingsViewModelWantsToEditDefaultBrowser() {
        let viewController = UIHostingController(rootView: EditDefaultBrowserView())

        let customHeight = Int(OptionRowHeight.compact.value) * Browser.allCases.count + 100
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func settingsViewModelWantsToEditTheme() {
        let view = EditThemeView(preferences: preferences)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.short.value) * Theme.allCases.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func settingsViewModelWantsToEditClipboardExpiration() {
        let view = EditClipboardExpirationView(preferences: preferences)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * ClipboardExpiration.allCases.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func settingsViewModelWantsToClearLogs() {
        Task {
            let modules = PassModule.allCases.map(LogManager.init)
            await modules.asyncForEach { await $0.removeAllLogs() }
            await MainActor.run { [weak self] in
                guard let self else { return }
                bannerManager.displayBottomSuccessMessage(#localized("All logs cleared"))
            }
        }
    }
}

// MARK: - GeneratePasswordCoordinatorDelegate

extension HomepageCoordinator: GeneratePasswordCoordinatorDelegate {
    func generatePasswordCoordinatorWantsToPresent(viewController: UIViewController) {
        present(viewController)
    }
}

// MARK: - CreateEditItemViewModelDelegate

extension HomepageCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelWantsToChangeVault() {
        let viewModel = VaultSelectorViewModel()
        let view = VaultSelectorView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = 66 * vaultsManager.getVaultCount() + 180
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func createEditItemViewModelWantsToAddCustomField(delegate: CustomFieldAdditionDelegate) {
        customCoordinator = CustomFieldAdditionCoordinator(rootViewController: rootViewController,
                                                           delegate: delegate)
        customCoordinator?.start()
    }

    func createEditItemViewModelWantsToEditCustomFieldTitle(_ uiModel: CustomFieldUiModel,
                                                            delegate: CustomFieldEditionDelegate) {
        customCoordinator = CustomFieldEditionCoordinator(rootViewController: rootViewController,
                                                          delegate: delegate,
                                                          uiModel: uiModel)
        customCoordinator?.start()
    }

    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem, type: ItemContentType) {
        addNewEvent(type: .create(type))
        dismissTopMostViewController(animated: true) { [weak self] in
            guard let self else { return }
            bannerManager.displayBottomInfoMessage(type.creationMessage)
        }
        vaultsManager.refresh()
        homepageTabDelegete?.homepageTabShouldChange(tab: .items)
        increaseCreatedItemsCountAndAskForReviewIfNecessary()
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {
        addNewEvent(type: .update(type))
        vaultsManager.refresh()
        searchViewModel?.refreshResults()
        itemDetailCoordinator?.refresh()
        dismissTopMostViewController { [weak self] in
            guard let self else { return }
            bannerManager.displayBottomInfoMessage(type.updateMessage)
        }
    }
}

// MARK: - CreateEditLoginViewModelDelegate

extension HomepageCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options, creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium()]
        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate) {
        let coordinator = makeCreateEditItemCoordinator()
        coordinator.presentGeneratePasswordForLoginItem(delegate: delegate)
    }
}

// MARK: - GeneratePasswordViewModelDelegate

extension HomepageCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        dismissTopMostViewController(animated: true) { [weak self] in
            guard let self else { return }
            clipboardManager.copy(text: password, bannerMessage: #localized("Password copied"))
        }
    }
}

// MARK: - EditableVaultListViewModelDelegate

extension HomepageCoordinator: EditableVaultListViewModelDelegate {
    func editableVaultListViewModelWantsToConfirmDelete(vault: Vault,
                                                        delegate: DeleteVaultAlertHandlerDelegate) {
        let handler = DeleteVaultAlertHandler(rootViewController: topMostViewController,
                                              vault: vault,
                                              delegate: delegate)
        handler.showAlert()
    }
}

// MARK: - ItemDetailViewModelDelegate

extension HomepageCoordinator: ItemDetailViewModelDelegate {
    func itemDetailViewModelWantsToGoBack(isShownAsSheet: Bool) {
        if isShownAsSheet {
            dismissTopMostViewController()
        } else {
            popTopViewController(animated: true)
        }
    }

    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent) {
        presentEditItemView(for: itemContent)
    }

    func itemDetailViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager.copy(text: text, bannerMessage: bannerMessage)
    }

    func itemDetailViewModelWantsToShowFullScreen(_ data: FullScreenData) {
        showFullScreen(data: data, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func itemDetailViewModelDidMoveToTrash(item: ItemTypeIdentifiable) {
        refresh()
        dismissTopMostViewController(animated: true) { [weak self] in
            guard let self else { return }
            let undoBlock: (PMBanner) -> Void = { [weak self] banner in
                guard let self else { return }
                banner.dismiss()
                itemContextMenuHandler.restore(item)
            }
            bannerManager.displayBottomInfoMessage(item.trashMessage,
                                                   dismissButtonTitle: #localized("Undo"),
                                                   onDismiss: undoBlock)
        }
        addNewEvent(type: .update(item.type))
    }
}

// MARK: - ItemContextMenuHandlerDelegate

extension HomepageCoordinator: ItemContextMenuHandlerDelegate {
    func itemContextMenuHandlerWantsToEditItem(_ itemContent: ItemContent) {
        presentEditItemView(for: itemContent)
    }
}

// MARK: - SearchViewModelDelegate

extension HomepageCoordinator: SearchViewModelDelegate {
    func searchViewModelWantsToViewDetail(of itemContent: Client.ItemContent) {
        presentItemDetailView(for: itemContent, asSheet: true)
        addNewEvent(type: .searchClick)
    }

    func searchViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                   delegate: SortTypeListViewModelDelegate) {
        presentSortTypeList(selectedSortType: selectedSortType, delegate: delegate)
    }
}

// MARK: - CreateEditVaultViewModelDelegate

extension HomepageCoordinator: CreateEditVaultViewModelDelegate {
    func createEditVaultViewModelDidEditVault() {
        dismissTopMostViewController(animated: true) { [weak self] in
            guard let self else { return }
            bannerManager.displayBottomInfoMessage(#localized("Vault updated"))
        }
        vaultsManager.refresh()
    }
}

// MARK: - LogsViewModelDelegate

extension HomepageCoordinator: LogsViewModelDelegate {
    func logsViewModelWantsToShareLogs(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if UIDevice.current.isIpad {
            activityVC.popoverPresentationController?.sourceView = topMostViewController.view
        }
        present(activityVC)
    }
}

// MARK: - SyncEventLoopDelegate

extension HomepageCoordinator: SyncEventLoopDelegate {
    func syncEventLoopDidStartLooping() {
        logger.info("Started looping")
    }

    func syncEventLoopDidStopLooping() {
        logger.info("Stopped looping")
    }

    func syncEventLoopDidBeginNewLoop() {
        logger.info("Began new sync loop")
    }

    #warning("Handle no connection reason")
    func syncEventLoopDidSkipLoop(reason: SyncEventLoopSkipReason) {
        logger.info("Skipped sync loop \(reason)")
    }

    func syncEventLoopDidFinishLoop(hasNewEvents: Bool) {
        if hasNewEvents {
            logger.info("Has new events. Refreshing items")
            refresh()
        } else {
            logger.info("Has no new events. Do nothing.")
        }
    }

    func syncEventLoopDidFailLoop(error: Error) {
        // Silently fail & not show error to users
        logger.error(error)
    }

    func syncEventLoopDidBeginExecutingAdditionalTask(label: String) {
        logger.trace("Began executing additional task \(label)")
    }

    func syncEventLoopDidFinishAdditionalTask(label: String) {
        logger.info("Finished executing additional task \(label)")
    }

    func syncEventLoopDidFailedAdditionalTask(label: String, error: Error) {
        logger.error(message: "Failed to execute additional task \(label)", error: error)
    }
}

private extension HomepageCoordinator {
    func parseNavigationConfig(config: NavigationConfiguration?) {
        guard let config else {
            return
        }
        if let event = config.telemetryEvent {
            addNewEvent(type: event)
        }

        if config.refresh {
            refresh()
        }
    }
}
