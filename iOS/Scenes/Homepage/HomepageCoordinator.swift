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
import Entities
import Factory
import MBProgressHUD
import ProtonCore_AccountDeletion
import ProtonCore_Login
import ProtonCore_Services
import ProtonCore_UIFoundations
import StoreKit
import SwiftUI
import UIComponents
import UIKit

protocol HomepageCoordinatorDelegate: AnyObject {
    func homepageCoordinatorWantsToLogOut()
    func homepageCoordinatorDidFailLocallyAuthenticating()
}

final class HomepageCoordinator: Coordinator, DeinitPrintable {
    deinit { print(deinitMessage) }

    // Injected & self-initialized properties
    private let clipboardManager = resolve(\SharedServiceContainer.clipboardManager)
    private let credentialManager = resolve(\SharedServiceContainer.credentialManager)
    private let eventLoop = resolve(\SharedServiceContainer.syncEventLoop)
    private let itemContextMenuHandler = resolve(\SharedServiceContainer.itemContextMenuHandler)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let paymentsManager = resolve(\ServiceContainer.paymentManager)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let telemetryEventRepository = resolve(\SharedRepositoryContainer.telemetryEventRepository)
    private let urlOpener = UrlOpener()
    private let passPlanRepository = resolve(\SharedRepositoryContainer.passPlanRepository)
    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let featureFlagsRepository = resolve(\SharedRepositoryContainer.featureFlagsRepository)
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let refreshInvitations = resolve(\UseCasesContainer.refreshInvitations)

    // Lazily initialized properties
    private lazy var bannerManager: BannerManager = .init(container: rootViewController)

    // Use cases
    private let refreshFeatureFlags = resolve(\UseCasesContainer.refreshFeatureFlags)
    private let addTelemetryEvent = resolve(\SharedUseCasesContainer.addTelemetryEvent)

    // References
    private weak var profileTabViewModel: ProfileTabViewModel?
    private weak var searchViewModel: SearchViewModel?
    private var itemDetailCoordinator: ItemDetailCoordinator?
    private var createEditItemCoordinator: CreateEditItemCoordinator?
    private var wordProvider: WordProviderProtocol?
    private var customCoordinator: CustomCoordinator?
    private var cancellables = Set<AnyCancellable>()

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: HomepageCoordinatorDelegate?
    weak var homepageTabDelegete: HomepageTabDelegete?

    override init() {
        super.init()
        setUpRouting()
        finalizeInitialization()
        vaultsManager.refresh()
        refreshInvitations()
        start()
        eventLoop.start()
        refreshPlan()
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
        clipboardManager.bannerManager = bannerManager
        itemContextMenuHandler.delegate = self
        passPlanRepository.delegate = self
        urlOpener.rootViewController = rootViewController

        preferences.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.rootViewController.setUserInterfaceStyle(self.preferences
                    .theme.userInterfaceStyle)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.eventLoop.stop()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.logger.info("App goes back to foreground")
                self.refresh()
                self.refreshInvitations()
                self.sendAllEventsIfApplicable()
                self.eventLoop.start()
                self.eventLoop.forceSync()
                self.refreshPlan()
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
            self?.popTopViewController(animated: true)
        }

        let homeView = HomepageTabbarView(itemsTabViewModel: itemsTabViewModel,
                                          profileTabViewModel: profileTabViewModel,
                                          homepageCoordinator: self,
                                          delegate: self)
            .ignoresSafeArea(edges: [.top, .bottom])
            .localAuthentication(delayed: false,
                                 onAuth: { [weak self] in
                                     self?.dismissAllViewControllers(animated: false)
                                     self?.hideSecondaryView()
                                 },
                                 onSuccess: { [weak self] in
                                     self?.showSecondaryView()
                                     self?.logger.info("Local authentication succesful")
                                 },
                                 onFailure: { [weak self] in
                                     guard let self else { return }
                                     self.logger.error("Failed to locally authenticate. Logging out.")
                                     self.delegate?.homepageCoordinatorDidFailLocallyAuthenticating()
                                 })

        start(with: homeView, secondaryView: placeholderView)
        rootViewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
    }

    func refreshPlan() {
        Task { [weak self] in
            do {
                try await self?.passPlanRepository.refreshPlan()
            } catch {
                self?.logger.error(error)
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
            do {
                try await self?.telemetryEventRepository.sendAllEventsIfApplicable()
            } catch {
                self?.logger.error(error)
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
                    self.urlOpener.open(urlString: url)
                }
            }
            .store(in: &cancellables)

        router
            .newSheetDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case .sharingFlow:
                    self.presentSharingFlow()
                case let .manageShareVault(vault, dismissPrevious):
                    self.presentManageShareVault(with: vault, dismissPrevious: dismissPrevious)
                case .filterItems:
                    self.presentItemFilterOptions()
                case let .acceptRejectInvite(invite):
                    self.presentAcceptRejectInvite(with: invite)
                case .upgradeFlow:
                    self.startUpgradeFlow()
                case let .vaultCreateEdit(vault: vault):
                    self.createEditVaultView(vault: vault)
                case let .logView(module: module):
                    self.presentLogsView(for: module)
                case let .suffixView(suffixSelection):
                    self.presentSuffixSelectionView(selection: suffixSelection)
                case let .mailboxView(mailboxSelection, mode):
                    self.presentMailboxSelectionView(selection: mailboxSelection,
                                                     mode: .createAliasLite,
                                                     titleMode: mode)
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
                        self.showLoadingHud()
                    } else {
                        self.hideLoadingHud()
                    }
                case let .displayErrorBanner(errorLocalized):
                    self.bannerManager.displayTopErrorMessage(errorLocalized)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - UI view presenting functions

    func presentSharingFlow() {
        let userEmailView = UserEmailView()
        present(userEmailView)
    }

    func createEditVaultView(vault: Vault?) {
        if let vault {
            presentCreateEditVaultView(mode: .edit(vault))
        } else {
            presentCreateEditVaultView(mode: .create)
        }
    }

    func presentManageShareVault(with vault: Vault, dismissPrevious: Bool) {
        let manageShareVaultView = ManageSharedVaultView(viewModel: ManageSharedVaultViewModel(vault: vault))

        if dismissPrevious {
            dismissTopMostViewController { [weak self] in
                guard let self else {
                    return
                }
                if let host = self.rootViewController
                    .topMostViewController as? UIHostingController<ManageSharedVaultView> {
                    /// Updating share data circumventing the onAppear not being called after a sheet presentation
                    host.rootView.refresh()
                    return
                }
                self.present(manageShareVaultView)
            }
        } else {
            present(manageShareVaultView)
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

        // 66 per row + nav bar height
        let customHeight = ItemType.allCases.count * 66 + 72
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentCreateItemView(for itemType: ItemType) {
        do {
            let coordinator = makeCreateEditItemCoordinator()
            try coordinator.presentCreateItemView(for: itemType)
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
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

    func startUpgradeFlow() {
        dismissAllViewControllers(animated: true) { [weak self] in
            self?.paymentsManager.upgradeSubscription { [weak self] result in
                switch result {
                case let .success(inAppPurchasePlan):
                    if inAppPurchasePlan != nil {
                        self?.refreshPlan()
                    } else {
                        self?.logger.debug("Payment is done but no plan is purchased")
                    }
                case let .failure(error):
                    self?.bannerManager.displayTopErrorMessage(error)
                }
            }
        }
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
        if preferences.onboarded { return }
        let onboardingViewModel = OnboardingViewModel(bannerManager: bannerManager)
        let onboardingView = OnboardingView(viewModel: onboardingViewModel)
        let onboardingViewController = UIHostingController(rootView: onboardingView)
        onboardingViewController.modalPresentationStyle = UIDevice.current.isIpad ? .formSheet : .fullScreen
        onboardingViewController.isModalInPresentation = true
        topMostViewController.present(onboardingViewController, animated: true)
    }
}

// MARK: - PassPlanRepositoryDelegate

extension HomepageCoordinator: PassPlanRepositoryDelegate {
    func passPlanRepositoryDidUpdateToNewPlan() {
        logger.trace("Found new plan, refreshing credential database")
        homepageTabDelegete?.homepageTabShouldRefreshTabIcons()
        profileTabViewModel?.refreshPlan()
    }
}

// MARK: - HomepageTabBarControllerDelegate

extension HomepageCoordinator: HomepageTabBarControllerDelegate {
    func homepageTabBarControllerDidSelectItemsTab() {
        if !isCollapsed() {
            let placeholderView = ItemDetailPlaceholderView { [weak self] in
                self?.popTopViewController(animated: true)
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
                self?.present(viewController)
            }

        case .dismissAllViewControllers:
            dismissAllViewControllers { [weak self] in
                self?.present(viewController)
            }
        }
    }

    func childCoordinatorWantsToDisplayBanner(bannerOption: ChildCoordinatorBannerOption,
                                              presentationOption: ChildCoordinatorPresentationOption) {
        let display: () -> Void = { [weak self] in
            guard let self else { return }
            switch bannerOption {
            case let .info(message):
                self.bannerManager.displayBottomInfoMessage(message)
            case let .success(message):
                self.bannerManager.displayBottomSuccessMessage(message)
            case let .error(message):
                self.bannerManager.displayTopErrorMessage(message)
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
            self?.presentCreateItemView(for: type)
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

                let plan = try await self.upgradeChecker.passPlanRepository.getPlan()
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
    func createEditItemCoordinatorWantsWordProvider() async -> WordProviderProtocol? {
        do {
            let wordProvider = try await WordProvider()
            self.wordProvider = wordProvider
            return wordProvider
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
            return nil
        }
    }

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

    func profileTabViewModelWantsToShowAcknowledgments() {
        print(#function)
    }

    func profileTabViewModelWantsToShowFeedback() {
        let view = FeedbackChannelsView { [weak self] selectedChannel in
            switch selectedChannel {
            case .bugReport:
                self?.dismissTopMostViewController(animated: true) { [weak self] in
                    self?.presentBugReportView()
                }
            default:
                if let urlString = selectedChannel.urlString {
                    self?.urlOpener.open(urlString: urlString)
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
            self?.bannerManager.displayTopErrorMessage(error)
        }
        let successHandler: () -> Void = { [weak self] in
            self?.dismissTopMostViewController { [weak self] in
                self?.bannerManager.displayBottomSuccessMessage("Report successfully sent")
            }
        }
        let view = BugReportView(onError: errorHandler, onSuccess: successHandler)
        present(view)
    }

    func profileTabViewModelWantsToQaFeatures() {
        let viewModel = QAFeaturesViewModel(bannerManager: bannerManager)
        let view = QAFeaturesView(viewModel: viewModel)
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
                                                           self?.hideLoadingHud(view)
                                                       },
                                                       completion: { [weak self] result in
                                                           guard let self else { return }
                                                           self.hideLoadingHud(view)
                                                           DispatchQueue.main.async {
                                                               switch result {
                                                               case .success:
                                                                   self.logger.trace("Account deletion successful")
                                                                   self.accountViewModelWantsToSignOut()
                                                               case .failure(AccountDeletionError.closedByUser):
                                                                   self.logger
                                                                       .trace("Accpunt deletion form closed by user")
                                                               case let .failure(error):
                                                                   self.logger.error(error)
                                                                   self.bannerManager
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

    func settingsViewModelWantsToEditDefaultBrowser(supportedBrowsers: [Browser]) {
        let view = EditDefaultBrowserView(supportedBrowsers: supportedBrowsers, preferences: preferences)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * supportedBrowsers.count + 140
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

    func settingsViewModelWantsToEdit(primaryVault: Vault) {
        let allVaults = vaultsManager.getAllVaultContents().map { VaultListUiModel(vaultContent: $0) }
        let viewModel = EditPrimaryVaultViewModel(allVaults: allVaults, primaryVault: primaryVault)
        viewModel.delegate = self
        let view = EditPrimaryVaultView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.medium.value) * vaultsManager.getVaultCount() + 60
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
                self?.bannerManager.displayBottomSuccessMessage("All logs cleared".localized)
            }
        }
    }

    func settingsViewModelDidFinishFullSync() {
        refresh()
        bannerManager.displayBottomSuccessMessage("Force synchronization done".localized)
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
    func createEditItemViewModelWantsToChangeVault(selectedVault: Vault,
                                                   delegate: VaultSelectorViewModelDelegate) {
        let vaultContents = vaultsManager.getAllVaultContents()
        let viewModel = VaultSelectorViewModel(allVaults: vaultContents.map { .init(vaultContent: $0) },
                                               selectedVault: selectedVault)
        viewModel.delegate = delegate
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
            self?.bannerManager.displayBottomInfoMessage(type.creationMessage)
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
            self?.bannerManager.displayBottomInfoMessage(type.updateMessage)
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

    func createEditLoginViewModelWantsToOpenSettings() {
        UIApplication.shared.openAppSettings()
    }
}

// MARK: - GeneratePasswordViewModelDelegate

extension HomepageCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        dismissTopMostViewController(animated: true) { [weak self] in
            self?.clipboardManager.copy(text: password, bannerMessage: "Password copied")
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

    func editableVaultListViewModelDidDelete(vault: Vault) {
        bannerManager.displayBottomInfoMessage("Vault \"\(vault.name)\" deleted")
        vaultsManager.refresh()
    }

    func editableVaultListViewModelDidRestoreAllTrashedItems() {
        bannerManager.displayBottomSuccessMessage("All items restored")
        refresh()
    }

    func editableVaultListViewModelDidPermanentlyDeleteAllTrashedItems() {
        bannerManager.displayBottomInfoMessage("All items permanently deleted")
        refresh()
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

    func itemDetailViewModelWantsToShowFullScreen(_ text: String) {
        showFullScreen(text: text,
                       theme: preferences.theme,
                       userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func itemDetailViewModelDidMove(item: ItemTypeIdentifiable, to vault: Vault) {
        dismissTopMostViewController(animated: true) { [weak self] in
            self?.bannerManager.displayBottomSuccessMessage("Item moved to vault \"\(vault.name)\"")
        }
        refresh()
        addNewEvent(type: .update(item.type))
    }

    func itemDetailViewModelWantsToMove(item: ItemIdentifiable, delegate: MoveVaultListViewModelDelegate) {
        let allVaults = vaultsManager.getAllVaultContents()
        guard !allVaults.isEmpty,
              let currentVault = allVaults.first(where: { $0.vault.shareId == item.shareId }) else { return }
        let viewModel = MoveVaultListViewModel(allVaults: allVaults.map { .init(vaultContent: $0) },
                                               currentVault: .init(vaultContent: currentVault))
        viewModel.delegate = delegate
        let view = MoveVaultListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = 66 * allVaults.count + 180
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func itemDetailViewModelDidMoveToTrash(item: ItemTypeIdentifiable) {
        refresh()
        dismissTopMostViewController(animated: true) { [weak self] in
            let undoBlock: (PMBanner) -> Void = { [weak self] banner in
                banner.dismiss()
                self?.itemContextMenuHandler.restore(item)
            }
            self?.bannerManager.displayBottomInfoMessage(item.trashMessage,
                                                         dismissButtonTitle: "Undo",
                                                         onDismiss: undoBlock)
        }
        addNewEvent(type: .update(item.type))
    }

    func itemDetailViewModelDidRestore(item: ItemTypeIdentifiable) {
        refresh()
        dismissTopMostViewController(animated: true) { [weak self] in
            self?.bannerManager.displayBottomSuccessMessage(item.type.restoreMessage)
        }
        addNewEvent(type: .update(item.type))
    }

    func itemDetailViewModelDidPermanentlyDelete(item: ItemTypeIdentifiable) {
        refresh()
        dismissTopMostViewController(animated: true) { [weak self] in
            self?.bannerManager.displayBottomInfoMessage(item.type.deleteMessage)
        }
        addNewEvent(type: .delete(item.type))
    }
}

// MARK: - ItemContextMenuHandlerDelegate

extension HomepageCoordinator: ItemContextMenuHandlerDelegate {
    func itemContextMenuHandlerWantsToEditItem(_ itemContent: ItemContent) {
        presentEditItemView(for: itemContent)
    }

    func itemContextMenuHandlerDidTrash(item: ItemTypeIdentifiable) {
        refresh()
        addNewEvent(type: .update(item.type))
    }

    func itemContextMenuHandlerDidUntrash(item: ItemTypeIdentifiable) {
        refresh()
        addNewEvent(type: .update(item.type))
    }

    func itemContextMenuHandlerDidPermanentlyDelete(item: ItemTypeIdentifiable) {
        refresh()
        addNewEvent(type: .delete(item.type))
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
    func createEditVaultViewModelDidCreateVault() {
        dismissTopMostViewController(animated: true) { [weak self] in
            self?.bannerManager.displayBottomSuccessMessage("Vault created")
        }
        vaultsManager.refresh()
    }

    func createEditVaultViewModelDidEditVault() {
        dismissTopMostViewController(animated: true) { [weak self] in
            self?.bannerManager.displayBottomInfoMessage("Changes saved")
        }
        vaultsManager.refresh()
    }
}

// MARK: - EditPrimaryVaultViewModelDelegate

extension HomepageCoordinator: EditPrimaryVaultViewModelDelegate {
    func editPrimaryVaultViewModelDidUpdatePrimaryVault() {
        dismissTopMostViewController(animated: true) { [weak self] in
            self?.bannerManager.displayBottomSuccessMessage("Primary vault updated".localized)
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
        refreshInvitations()

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
}
