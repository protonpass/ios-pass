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

    // Lazily initialized properties
    private lazy var bannerManager: BannerManager = .init(container: rootViewController)

    // References
    private weak var profileTabViewModel: ProfileTabViewModel?
    private weak var searchViewModel: SearchViewModel?
    private var itemDetailCoordinator: ItemDetailCoordinator?
    private var createEditItemCoordinator: CreateEditItemCoordinator?
    private var wordProvider: WordProviderProtocol?
    private var customCoordinator: CustomCoordinator?
    private var cancellables = Set<AnyCancellable>()

    private let router = resolve(\RouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: HomepageCoordinatorDelegate?
    weak var homepageTabDelegete: HomepageTabDelegete?

    override init() {
        super.init()
        setUpRouting()
        finalizeInitialization()
        vaultsManager.refresh()
        start()
        eventLoop.start()
        refreshPlan()
        refreshFeatureFlags()
        sendAllEventsIfApplicable()
    }
}

// MARK: - Private APIs

private extension HomepageCoordinator {
    /// Some properties are dependant on other propeties which are in turn not initialized
    /// before the Coordinator is fully initialized. This method is to resolve these dependencies.
    func finalizeInitialization() {
        eventLoop.delegate = self
        clipboardManager.bannerManager = bannerManager
        itemContextMenuHandler.delegate = self
        passPlanRepository.delegate = self
        (itemRepository as? ItemRepository)?.delegate = credentialManager as? CredentialManager
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
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.logger.info("App goes back to foreground")
                self.refresh()
                self.sendAllEventsIfApplicable()
                self.eventLoop.forceSync()
                self.updateCredentials(forceRemoval: false)
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

        let placeholderView = ItemDetailPlaceholderView { [unowned self] in
            popTopViewController(animated: true)
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
        Task {
            do {
                try await passPlanRepository.refreshPlan()
            } catch {
                logger.error(error)
            }
        }
    }

    func refreshFeatureFlags() {
        Task {
            do {
                try await featureFlagsRepository.refreshFlags()
            } catch {
                logger.error(error)
            }
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

    func makeCreateEditItemCoordinator() -> CreateEditItemCoordinator {
        let coordinator = CreateEditItemCoordinator(createEditItemDelegates: self)
        coordinator.delegate = self
        createEditItemCoordinator = coordinator
        return coordinator
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
        viewModel.delegate = self
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
        viewModel.delegate = self
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

    func refresh() {
        vaultsManager.refresh()
        searchViewModel?.refreshResults()
        itemDetailCoordinator?.refresh()
        createEditItemCoordinator?.refresh()
    }

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

    func presentLogsView(for module: PassModule) {
        let viewModel = LogsViewModel(module: module)
        viewModel.delegate = self
        let view = LogsView(viewModel: viewModel)
        present(view)
    }

    func addNewEvent(type: TelemetryEventType) {
        Task {
            do {
                try await telemetryEventRepository.addNewEvent(type: type)
            } catch {
                logger.error(error)
            }
        }
    }

    func sendAllEventsIfApplicable() {
        Task {
            do {
                try await telemetryEventRepository.sendAllEventsIfApplicable()
            } catch {
                logger.error(error)
            }
        }
    }

    func updateCredentials(forceRemoval: Bool) {
        Task {
            do {
                try await credentialManager.insertAllCredentials(itemRepository: itemRepository,
                                                                 shareRepository: shareRepository,
                                                                 passPlanRepository: passPlanRepository,
                                                                 forceRemoval: forceRemoval)
                logger.info("Updated all credentials.")
            } catch {
                logger.error(error)
            }
        }
    }

    func startUpgradeFlow() {
        dismissAllViewControllers(animated: true) { [unowned self] in
            paymentsManager.upgradeSubscription { [weak self] result in
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

// MARK: - Navigation & Routing

private extension HomepageCoordinator {
    func setUpRouting() {
        router
            .newPresentationDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("plop")
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
                case .manageShareVault:
                    self.presentManageShareVault()
                case .filterItems:
                    self.presentItemFilterOptions()
                }
            }
            .store(in: &cancellables)
    }

    func presentSharingFlow() {
        let userEmailView = UserEmailView()
        present(userEmailView)
    }

    func presentManageShareVault() {
        dismissTopMostViewController { [weak self] in
            let manageShareVaultView = Text("Manage Share Vault Screen")
            self?.present(manageShareVaultView)
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
        updateCredentials(forceRemoval: true)
        homepageTabDelegete?.homepageTabShouldRefreshTabIcons()
        profileTabViewModel?.refreshPlan()
    }
}

// MARK: - HomepageTabBarControllerDelegate

extension HomepageCoordinator: HomepageTabBarControllerDelegate {
    func homepageTabBarControllerDidSelectItemsTab() {
        if !isCollapsed() {
            let placeholderView = ItemDetailPlaceholderView { [unowned self] in
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

    func childCoordinatorDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - ItemTypeListViewModelDelegate

extension HomepageCoordinator: ItemTypeListViewModelDelegate {
    func itemTypeListViewModelDidSelect(type: ItemType) {
        dismissTopMostViewController { [unowned self] in
            presentCreateItemView(for: type)
        }
    }

    func itemTypeListViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - ItemsTabViewModelDelegate

extension HomepageCoordinator: ItemsTabViewModelDelegate {
    func itemsTabViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func itemsTabViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

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
        Task { @MainActor in
            defer { hideLoadingHud() }
            do {
                showLoadingHud()

                let plan = try await upgradeChecker.passPlanRepository.getPlan()
                guard let trialEnd = plan.trialEnd else { return }
                let trialEndDate = Date(timeIntervalSince1970: TimeInterval(trialEnd))
                let daysLeft = Calendar.current.numberOfDaysBetween(trialEndDate, and: .now)

                hideLoadingHud()

                let view = TrialDetailView(daysLeft: abs(daysLeft),
                                           onUpgrade: startUpgradeFlow,
                                           onLearnMore: { self.urlOpener.open(urlString: ProtonLink.trialPeriod) })
                present(view)
            } catch {
                logger.error(error)
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }

    func itemsTabViewModelWantsViewDetail(of itemContent: Client.ItemContent) {
        presentItemDetailView(for: itemContent, asSheet: shouldShowAsSheet())
    }

    func itemsTabViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
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
    func profileTabViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func profileTabViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func profileTabViewModelWantsToUpgrade() {
        startUpgradeFlow()
    }

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

    func profileTabViewModelWantsToShowPrivacyPolicy() {
        urlOpener.open(urlString: ProtonLink.privacyPolicy)
    }

    func profileTabViewModelWantsToShowTermsOfService() {
        urlOpener.open(urlString: ProtonLink.termsOfService)
    }

    func profileTabViewModelWantsToShowImportInstructions() {
        urlOpener.open(urlString: ProtonLink.howToImport)
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

    func profileTabViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
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
    func settingsViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func settingsViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

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

    func settingsViewModelWantsToViewHostAppLogs() {
        presentLogsView(for: .hostApp)
    }

    func settingsViewModelWantsToViewAutoFillExtensionLogs() {
        presentLogsView(for: .autoFillExtension)
    }

    func settingsViewModelWantsToClearLogs() {
        Task {
            let modules = PassModule.allCases.map(LogManager.init)
            await modules.asyncForEach { await $0.removeAllLogs() }
            await MainActor.run { [weak self] in
                self?.bannerManager.displayBottomSuccessMessage("All logs cleared")
            }
        }
    }

    func settingsViewModelDidFinishFullSync() {
        refresh()
        bannerManager.displayBottomSuccessMessage("Force synchronization done")
    }

    func settingsViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
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
    func createEditItemViewModelWantsToShowLoadingHud() {
        showLoadingHud()
    }

    func createEditItemViewModelWantsToHideLoadingHud() {
        hideLoadingHud()
    }

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

    func createEditItemViewModelWantsToUpgrade() {
        startUpgradeFlow()
    }

    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem, type: ItemContentType) {
        addNewEvent(type: .create(type))
        dismissTopMostViewController(animated: true) { [unowned self] in
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
        dismissTopMostViewController { [unowned self] in
            bannerManager.displayBottomInfoMessage(type.updateMessage)
        }
    }

    func createEditItemViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditLoginViewModelDelegate

extension HomepageCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options, creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        viewModel.delegate = self
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

// MARK: - CreateEditAliasViewModelDelegate

extension HomepageCoordinator: CreateEditAliasViewModelDelegate {
    func createEditAliasViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection,
                                                        titleMode: MailboxSection.Mode) {
        presentMailboxSelectionView(selection: mailboxSelection,
                                    mode: .createEditAlias,
                                    titleMode: titleMode)
    }

    func createEditAliasViewModelWantsToSelectSuffix(_ suffixSelection: SuffixSelection) {
        presentSuffixSelectionView(selection: suffixSelection)
    }
}

// MARK: - MailboxSelectionViewModelDelegate

extension HomepageCoordinator: MailboxSelectionViewModelDelegate {
    func mailboxSelectionViewModelWantsToUpgrade() {
        startUpgradeFlow()
    }

    func mailboxSelectionViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - SuffixSelectionViewModelDelegate

extension HomepageCoordinator: SuffixSelectionViewModelDelegate {
    func suffixSelectionViewModelWantsToUpgrade() {
        startUpgradeFlow()
    }

    func suffixSelectionViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - CreateAliasLiteViewModelDelegate

extension HomepageCoordinator: CreateAliasLiteViewModelDelegate {
    func createAliasLiteViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection) {
        presentMailboxSelectionView(selection: mailboxSelection,
                                    mode: .createAliasLite,
                                    titleMode: .create)
    }

    func createAliasLiteViewModelWantsToSelectSuffix(_ suffixSelection: SuffixSelection) {
        presentSuffixSelectionView(selection: suffixSelection)
    }

    func createAliasLiteViewModelWantsToUpgrade() {
        startUpgradeFlow()
    }
}

// MARK: - GeneratePasswordViewModelDelegate

extension HomepageCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            clipboardManager.copy(text: password, bannerMessage: "Password copied")
        }
    }
}

// MARK: - EditableVaultListViewModelDelegate

extension HomepageCoordinator: EditableVaultListViewModelDelegate {
    func editableVaultListViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func editableVaultListViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func editableVaultListViewModelWantsToCreateNewVault() {
        presentCreateEditVaultView(mode: .create)
    }

    func editableVaultListViewModelWantsToEdit(vault: Vault) {
        presentCreateEditVaultView(mode: .edit(vault))
    }

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

    func editableVaultListViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
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
    func itemDetailViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func itemDetailViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

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

    func itemDetailViewModelWantsToOpen(urlString: String) {
        urlOpener.open(urlString: urlString)
    }

    func itemDetailViewModelDidMove(item: ItemTypeIdentifiable, to vault: Vault) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager.displayBottomSuccessMessage("Item moved to vault \"\(vault.name)\"")
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

    func itemDetailViewModelWantsToUpgrade() {
        startUpgradeFlow()
    }

    func itemDetailViewModelDidMoveToTrash(item: ItemTypeIdentifiable) {
        refresh()
        dismissTopMostViewController(animated: true) { [unowned self] in
            let undoBlock: (PMBanner) -> Void = { [unowned self] banner in
                banner.dismiss()
                itemContextMenuHandler.restore(item)
            }
            bannerManager.displayBottomInfoMessage(item.trashMessage,
                                                   dismissButtonTitle: "Undo",
                                                   onDismiss: undoBlock)
        }
        addNewEvent(type: .update(item.type))
    }

    func itemDetailViewModelDidRestore(item: ItemTypeIdentifiable) {
        refresh()
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager.displayBottomSuccessMessage(item.type.restoreMessage)
        }
        addNewEvent(type: .update(item.type))
    }

    func itemDetailViewModelDidPermanentlyDelete(item: ItemTypeIdentifiable) {
        refresh()
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager.displayBottomInfoMessage(item.type.deleteMessage)
        }
        addNewEvent(type: .delete(item.type))
    }

    func itemDetailViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - ItemContextMenuHandlerDelegate

extension HomepageCoordinator: ItemContextMenuHandlerDelegate {
    func itemContextMenuHandlerWantsToShowSpinner() {
        showLoadingHud()
    }

    func itemContextMenuHandlerWantsToHideSpinner() {
        hideLoadingHud()
    }

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

    func searchViewModelWantsDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditVaultViewModelDelegate

extension HomepageCoordinator: CreateEditVaultViewModelDelegate {
    func createEditVaultViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func createEditVaultViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func createEditVaultViewModelWantsToUpgrade() {
        startUpgradeFlow()
    }

    func createEditVaultViewModelDidCreateVault() {
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager.displayBottomSuccessMessage("Vault created")
        }
        vaultsManager.refresh()
    }

    func createEditVaultViewModelDidEditVault() {
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager.displayBottomInfoMessage("Changes saved")
        }
        vaultsManager.refresh()
    }

    func createEditVaultViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - EditPrimaryVaultViewModelDelegate

extension HomepageCoordinator: EditPrimaryVaultViewModelDelegate {
    func editPrimaryVaultViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func editPrimaryVaultViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func editPrimaryVaultViewModelDidUpdatePrimaryVault() {
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager.displayBottomSuccessMessage("Primary vault updated")
        }
        vaultsManager.refresh()
    }

    func editPrimaryVaultViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - LogsViewModelDelegate

extension HomepageCoordinator: LogsViewModelDelegate {
    func logsViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func logsViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func logsViewModelWantsToShareLogs(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if UIDevice.current.isIpad {
            activityVC.popoverPresentationController?.sourceView = topMostViewController.view
        }
        present(activityVC)
    }

    func logsViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
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
}
