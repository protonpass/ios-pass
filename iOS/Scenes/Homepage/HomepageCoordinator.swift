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
@preconcurrency import CryptoKit
import DesignSystem
import Entities
import FactoryKit
import Macro
import MBProgressHUD
import ProtonCoreAccountDeletion
import ProtonCoreAccountRecovery
import ProtonCoreDataModel
@preconcurrency import ProtonCoreLogin
import ProtonCoreLoginUI
import ProtonCoreNetworking
import ProtonCorePasswordChange
import ProtonCoreUIFoundations
import Screens
import StoreKit
import SwiftUI

private let kRefreshInvitationsTaskLabel = "RefreshInvitationsTask"

@MainActor
protocol HomepageCoordinatorDelegate: AnyObject {
    func homepageCoordinatorWantsToLogOut()
    func homepageCoordinatorDidFailLocallyAuthenticating(_ errorMessage: String?)
}

final class HomepageCoordinator: Coordinator, DeinitPrintable {
    deinit { print(deinitMessage) }

    // Injected & self-initialized properties
    let logger = resolve(\SharedToolingContainer.logger)
    private let paymentsManager = resolve(\ServiceContainer.paymentManager)
    let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)
    private let telemetryEventRepository = resolve(\SharedRepositoryContainer.telemetryEventRepository)
    let urlOpener = UrlOpener()
    let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let organizationRepository = resolve(\SharedRepositoryContainer.organizationRepository)
    let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    private let refreshInvitations = resolve(\UseCasesContainer.refreshInvitations)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)
    private let userSettingsRepository = resolve(\SharedRepositoryContainer.userSettingsRepository)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)

    // App cover/local authentication
    @LazyInjected(\RouterContainer.window) var window
    weak var appCoverView: UIView?

    // Lazily initialised properties
    @LazyInjected(\SharedServiceContainer.syncEventLoop) var eventLoop
    @LazyInjected(\SharedViewContainer.bannerManager) var bannerManager
    @LazyInjected(\SharedToolingContainer.apiManager) var apiManager
    @LazyInjected(\SharedToolingContainer.authManager) var authManager
    @LazyInjected(\SharedServiceContainer.upgradeChecker) var upgradeChecker
    @LazyInjected(\SharedServiceContainer.userManager) var userManager
    @LazyInjected(\SharedServiceContainer.inAppNotificationManager) var inAppNotificationManager
    @LazyInjected(\SharedRepositoryContainer.itemRepository) var itemRepository
    @LazyInjected(\SharedRepositoryContainer.shareRepository) var shareRepository
    @LazyInjected(\SharedRepositoryContainer.passMonitorRepository) var passMonitorRepository
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) var aliasRepository
    @LazyInjected(\SharedRepositoryContainer.passwordHistoryRepository)
    private var passwordHistoryRepository
    @LazyInjected(\ServiceContainer.onboardingHandler) private var onboardingHandler
    @LazyInjected(\SharedServiceContainer.featureDiscoveryManager)
    private var featureDiscoveryManager

    // Use cases
    private let refreshFeatureFlags = resolve(\SharedUseCasesContainer.refreshFeatureFlags)
    let revokeCurrentSession = resolve(\SharedUseCasesContainer.revokeCurrentSession)
    private let makeAccountSettingsUrl = resolve(\UseCasesContainer.makeAccountSettingsUrl)
    private let refreshUserSettings = resolve(\SharedUseCasesContainer.refreshUserSettings)
    private let overrideSecuritySettings = resolve(\UseCasesContainer.overrideSecuritySettings)
    private let copyToClipboard = resolve(\SharedUseCasesContainer.copyToClipboard)
    private let refreshAccessAndMonitorState = resolve(\UseCasesContainer.refreshAccessAndMonitorState)
    @LazyInjected(\UseCasesContainer.logOutExcessFreeAccounts) private var logOutExcessFreeAccounts
    @LazyInjected(\UseCasesContainer.canAddNewAccount) var canAddNewAccount
    @LazyInjected(\SharedUseCasesContainer.switchUser) var switchUser
    @LazyInjected(\SharedUseCasesContainer.logOutUser) var logOutUser
    @LazyInjected(\SharedUseCasesContainer.sendUserMonitoringStats) private var sendUserMonitoringStats
    @LazyInjected(\SharedUseCasesContainer.addAndSwitchToNewUserAccount)
    var addAndSwitchToNewUserAccount
    @LazyInjected(\ SharedUseCasesContainer.addTelemetryEvent) var addTelemetryEvent
    @LazyInjected(\SharedUseCasesContainer.setUpBeforeLaunching) private var setUpBeforeLaunching
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) var getFeatureFlagStatus
    @LazyInjected(\SharedUseCasesContainer.fullContentSync) var fullContentSync

    private let getAppPreferences = resolve(\SharedUseCasesContainer.getAppPreferences)
    let updateAppPreferences = resolve(\SharedUseCasesContainer.updateAppPreferences)
    let getSharedPreferences = resolve(\SharedUseCasesContainer.getSharedPreferences)
    let getUserPreferences = resolve(\SharedUseCasesContainer.getUserPreferences)

    // References
    private weak var itemsTabViewModel: ItemsTabViewModel?
    private var itemDetailCoordinator: ItemDetailCoordinator?
    private var createEditItemCoordinator: CreateEditItemCoordinator?
    private var cancellables = Set<AnyCancellable>()

    lazy var logInAndSignUp = makeLoginAndSignUp()

    // MARK: - Navigation Router

    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    var authenticated = false

    weak var delegate: (any HomepageCoordinatorDelegate)?
    weak var homepageTabDelegate: (any HomepageTabDelegate)?

    override init() {
        super.init()
        SharedViewContainer.shared.register(rootViewController: rootViewController)
        setUpRouting()
        finalizeInitialization()
        start()
        synchroniseData()
        loadAccesses { [weak self] in
            // Do not suggest SL sync if the user just logged in
            // to avoid showing too many things (onboarding, full sync progress...)
            guard let self, await !loginMethod.isManualLogIn() else { return }
            try await suggestSimpleLoginSyncIfApplicable()
        }
        refreshOrganizationAndOverrideSecuritySettings()
        refreshAccessAndMonitorStateSync()
        refreshSettings()
        refreshFeatureFlags()
        sendAllEventsIfApplicable()
        doLogOutExcessFreeAccounts()
        cleanUpPasswordHistory()
    }
}

// MARK: - Private APIs & Setup & Utils

private extension HomepageCoordinator {
    /// Some properties are dependant on other propeties which are in turn not initialized
    /// before the Coordinator is fully initialized. This method is to resolve these dependencies.
    func finalizeInitialization() { // swiftlint:disable:this cyclomatic_complexity function_body_length
        eventLoop.delegate = self
        urlOpener.rootViewController = rootViewController

        // User event caches invites locally so no need to fetch invites as part of event loop
        if !getFeatureFlagStatus(for: FeatureFlagType.passUserEventsV1) {
            eventLoop.addAdditionalTask(.init(label: kRefreshInvitationsTaskLabel,
                                              task: refreshInvitations.callAsFunction))
        }

        authenticated = getSharedPreferences().localAuthenticationMethod == .none

        accessRepository.didUpdateToNewPlan
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                homepageTabDelegate?.refreshTabIcons()
            }
            .store(in: &cancellables)

        var isFirstLaunched = true
        userManager.currentActiveUser
            .receive(on: DispatchQueue.main)
            .compactMap(\.self)
            .removeDuplicates(by: { $0.user.ID == $1.user.ID })
            .sink { [weak self] userData in
                guard let self else { return }
                homepageTabDelegate?.refreshTabIcons()

                let email = userData.user.email ?? ""
                let message = isFirstLaunched ?
                    #localized("Signed in as %@", email) : #localized("Switched to %@", email)
                isFirstLaunched = false

                if rootViewController.presentedViewController == nil {
                    bannerManager.displayBottomInfoMessage(message)
                }
                removeInAppNotificationDisplay()
                refreshInAppNotifications()

                Task { [weak self] in
                    guard let self else { return }
                    let disallowed: [NewFeature] = if getFeatureFlagStatus(for: FeatureFlagType.passCustomTypeV1) {
                        []
                    } else {
                        [NewFeature.customItems]
                    }
                    await featureDiscoveryManager.refreshState(userId: userData.user.ID,
                                                               disallowedFeatures: Set(disallowed))
                }
            }
            .store(in: &cancellables)

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else {
                return
            }
            Task { [weak self] in
                guard let self else { return }
                guard await authenticated,
                      let destination = await router.getDeeplink() else { return }
                switch destination {
                case let .totp(uri):
                    await totpDeepLink(totpUri: uri)
                case let .spotlightItemDetail(itemContent):
                    await router.present(for: .itemDetail(itemContent))
                case let .error(error):
                    await router.display(element: .displayErrorBanner(error))
                }
                await router.resolveDeeplink()
            }
        }

        Publishers.CombineLatest(appContentManager.$vaultSelection, appContentManager.$state)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selection, _ in
                guard let self else { return }
                var createButtonDisabled = false
                switch selection {
                case .all, .trash:
                    let vaults = appContentManager.getAllShares()
                    createButtonDisabled = !vaults.contains(where: \.canEdit)
                case let .precise(vault):
                    createButtonDisabled = !vault.canEdit
                default:
                    createButtonDisabled = true
                }
                homepageTabDelegate?.disableCreateButton(createButtonDisabled)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                coverApp()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                coverApp()
                eventLoop.stop()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        logger.info("App goes back to foreground")
                        if let window {
                            // Configurations could be changed from extensions
                            // (logged out, token refreshed...), so we need to set up
                            // everything as if the app is first launched
                            try await setUpBeforeLaunching(rootContainer: .window(window))
                        } else {
                            assertionFailure("window should not be nil")
                        }
                        refresh(exitEditMode: false)
                        sendAllEventsIfApplicable()
                        eventLoop.start()
                        eventLoop.forceSync()
                        refreshAccessAndMonitorStateSync()
                        refreshSettings()
                        refreshFeatureFlags()
                        refreshInAppNotifications()
                        doLogOutExcessFreeAccounts()
                        try await sendUserMonitoringStats()
                    } catch {
                        logger.error(error)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        let itemsTabViewModel = ItemsTabViewModel()
        itemsTabViewModel.delegate = self

        itemsTabViewModel.$isEditMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditMode in
                guard let self else { return }
                homepageTabDelegate?.hideTabbar(isEditMode)
            }
            .store(in: &cancellables)

        self.itemsTabViewModel = itemsTabViewModel

        let profileTabViewModel = ProfileTabViewModel(childCoordinatorDelegate: self)
        profileTabViewModel.delegate = self

        let placeholderView = ItemDetailPlaceholderView { [weak self] in
            guard let self else { return }
            popTopViewController(animated: true)
        }

        let homeView = HomepageTabbarView(itemsTabViewModel: itemsTabViewModel,
                                          profileTabViewModel: profileTabViewModel,
                                          passMonitorViewModel: PassMonitorViewModel(),
                                          homepageCoordinator: self,
                                          delegate: self)
            .ignoresSafeArea(edges: [.top, .bottom])
            .onFirstAppear { [weak self] in
                guard let self else { return }
                coverApp()
            }

        start(with: homeView, secondaryView: placeholderView)
    }

    func synchroniseData() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.refresh(userId: userId)
                eventLoop.forceSync()
                eventLoop.start()
            } catch {
                logger.error(error)
            }
        }
    }

    func refreshAccessAndMonitorStateSync() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                try await refreshAccessAndMonitorState(userId: userId)
            } catch {
                logger.error(error)
            }
        }
    }

    func loadAccesses(completion: @escaping () async throws -> Void) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await accessRepository.loadAccesses()
                try await completion()
            } catch {
                logger.error(error)
            }
        }
    }

    func refreshOrganizationAndOverrideSecuritySettings() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                if let organization = try await organizationRepository.refreshOrganization(userId: userId) {
                    try await overrideSecuritySettings(with: organization)
                }
            } catch {
                logger.error(error)
            }
        }
    }

    func refreshSettings() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                try await refreshUserSettings(for: userId)
            } catch {
                logger.error(error)
            }
        }
    }

    func refresh(exitEditMode: Bool = true) {
        Task { [weak self] in
            guard let self else {
                return
            }
            if exitEditMode {
                itemsTabViewModel?.isEditMode = false
            }
            itemsTabViewModel?.refresh()
            itemDetailCoordinator?.refresh()
            createEditItemCoordinator?.refresh()
        }
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

    func doLogOutExcessFreeAccounts() {
        Task { [weak self] in
            guard let self else { return }
            do {
                if try await logOutExcessFreeAccounts() {
                    let message = #localized("You're logged out from other free accounts")
                    bannerManager.displayBottomInfoMessage(message)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func cleanUpPasswordHistory() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await passwordHistoryRepository.cleanUpOldPasswords()
            } catch {
                handle(error: error)
            }
        }
    }

    func increaseCreatedItemsCountAndAskForReviewIfNecessary() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let currentCount = getAppPreferences().createdItemsCount
                try await updateAppPreferences(\.createdItemsCount, value: currentCount + 1)
                // Only ask for reviews when not in macOS because macOS doesn't respect 3 times per year limit
                if !ProcessInfo.processInfo.isiOSAppOnMac,
                   currentCount >= 10,
                   let windowScene = rootViewController.view.window?.windowScene {
                    AppStore.requestReview(in: windowScene)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    /// Filters task cancellation errors as they should not be shown to the user
    /// - Parameter error: The current error to check
    /// - Returns: A boolean to indicate if we should display the error banner
    func shouldDisplayError(error: any Error) -> Bool {
        if error is CancellationError { return false }

        if let urlError = error as? URLError,
           urlError.code == .cancelled {
            return false
        }
        return true
    }
}

// MARK: - Navigation & Routing & View presentation

extension HomepageCoordinator {
    // MARK: - Router setup

    // swiftlint:disable:next cyclomatic_complexity function_body_length
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
            .itemDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .createEdit(view, dismissible):
                    createEditItemCoordinatorWantsToPresent(view: view, dismissable: dismissible)
                case let .detail(view, asSheet):
                    itemDetailCoordinatorWantsToPresent(view: view, asSheet: asSheet)
                }
            }
            .store(in: &cancellables)

        router
            .newSheetDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .alert(alert):
                    present(alert)
                case let .sharingFlow(dismissal):
                    presentSharingFlow(dismissal: dismissal)
                case let .manageSharedShare(display, dismissal):
                    presentManageSharedShare(with: display, dismissal: dismissal)
                case let .acceptRejectInvite(invite):
                    presentAcceptRejectInvite(with: invite)
                case .upgradeFlow:
                    startUpgradeFlow()
                case let .upselling(configuration, dismissal):
                    startUpsellingFlow(configuration: configuration, dismissal: dismissal)
                case let .vaultCreateEdit(vault: vault):
                    createEditVaultView(vault: vault)
                case let .logView(module: module):
                    presentLogsView(for: module)
                case .autoFillInstructions:
                    present(AutoFillInstructionsView())
                case let .moveItemsBetweenVaults(context):
                    itemMoveBetweenVault(context: context)
                case .fullSync:
                    present(FullSyncProgressView(mode: .fullSync), dismissible: false)
                case let .shareVaultFromItemDetail(vault, itemContent):
                    presentShareElementView(for: vault, itemContent: itemContent)
                case let .customizeNewVault(vault, itemContent):
                    presentCreateEditVaultView(mode: .editNewVault(vault, itemContent))
                case .setPINCode:
                    presentSetPINCodeView()
                case let .history(item):
                    presentItemHistory(item)
                case .restoreHistory:
                    updateAfterRestoration()
                case .tutorial:
                    openTutorialVideo()
                case .accountSettings:
                    beginAccountSettingsFlow()
                case .securityKeys:
                    presentSecurityKeys()
                case .settingsMenu:
                    profileTabViewModelWantsToShowSettingsMenu()
                case let .createEditLogin(item):
                    presentCreateEditLoginView(mode: item)
                case let .createItem(item, type, _):
                    handleItemCreation(item: item, type: type)
                case let .editItem(itemContent):
                    presentEditItemView(for: itemContent)
                case let .cloneItem(itemContent):
                    presentCloneItemView(for: itemContent)
                case let .updateItem(type: type, updated: upgrade):
                    createEditItemViewModelDidUpdateItem(type, updated: upgrade)
                case let .itemDetail(content,
                                     automaticDisplay,
                                     showSecurityIssues):
                    presentItemDetailView(for: content,
                                          asSheet: automaticDisplay ? shouldShowAsSheet() : true,
                                          showSecurityIssues: showSecurityIssues)
                case .editSpotlightSearchableContent:
                    presentEditSpotlightSearchableContentView()
                case .editSpotlightSearchableVaults:
                    presentEditSpotlightSearchableVaultsView()
                case .editSpotlightVaults:
                    presentEditSpotlightVaultsView()
                case let .passkeyDetail(passkey):
                    presentPasskeyDetailView(for: passkey)
                case let .securityDetail(securityWeakness):
                    presentSecurity(securityWeakness)
                case let .passwordReusedItemList(content):
                    presentPasswordReusedListView(for: content)
                case let .changePassword(mode):
                    presentChangePassword(mode: mode)
                case let .createSecureLink(item, share):
                    presentCreateSecureLinkView(for: item, and: share)
                case .enableExtraPassword:
                    beginEnableExtraPasswordFlow()
                case .secureLinks:
                    presentSecureLinks()
                case let .secureLinkDetail(link):
                    presentSecureLinkDetail(link: link)
                case .addAccount:
                    beginAddAccountFlow()
                case let .simpleLoginSyncActivation(dismissAllSheets):
                    if dismissAllSheets {
                        dismissAllViewControllers { [weak self] in
                            guard let self else { return }
                            present(SimpleLoginAliasActivationView())
                        }
                    } else {
                        present(SimpleLoginAliasActivationView())
                    }
                case .aliasesSyncConfiguration:
                    present(AliasSyncConfigurationView())
                case .loginsWith2fa:
                    presentLoginsWith2faView()
                case let .breachDetail(breach):
                    presentBreachDetail(breach: breach)
                case let .breach(breach):
                    presentBreach(breach: breach)
                case .addMailbox:
                    dismissTopMostViewController { [weak self] in
                        guard let self else { return }
                        present(AddCustomEmailView(viewModel: .init(validationType: .mailbox(nil))))
                    }
                case .passwordHistory:
                    presentPasswordHistoryView()
                case .signInToAnotherDevice:
                    presentSignInToAnotherDeviceView()
                case let .undecryptableSharesBanner(dismissTopSheetBeforeShowing):
                    displayUndecryptableSharesBanner(dismissTopSheetBeforeShowing)
                case let .shareLogs(url):
                    presentShareSheet(for: url)
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
                    guard shouldDisplayError(error: errorLocalized) else {
                        return
                    }
                    bannerManager.displayTopErrorMessage(errorLocalized)
                case let .errorMessage(message):
                    bannerManager.displayTopErrorMessage(message)
                case let .successMessage(message, config):
                    displaySuccessBanner(with: message, and: config)
                case let .infosMessage(message, showWhenNoSheets, config):
                    if !showWhenNoSheets ||
                        (showWhenNoSheets && rootViewController.presentedViewController == nil) {
                        displayInfoBanner(with: message, and: config)
                    }
                }
            }
            .store(in: &cancellables)

        router
            .alertDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .bulkPermanentDeleteConfirmation(itemCount, aliasCount):
                    presentBulkPermanentDeleteConfirmation(itemCount: itemCount,
                                                           aliasCount: aliasCount)
                }
            }
            .store(in: &cancellables)

        router.actionDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .copyToClipboard(text, message):
                    copyToClipboard(text, bannerMessage: message, bannerDisplay: bannerManager)
                case let .back(isShownAsSheet):
                    itemDetailViewModelWantsToGoBack(isShownAsSheet: isShownAsSheet)
                case let .manage(userId):
                    handleManageAccount(userId: userId)
                case let .signOut(userId):
                    handleSignOut(userId: userId)
                case let .deleteAccount(userId):
                    deleteAccount(userId: userId)
                case let .screenDismissal(dismissal):
                    switch dismissal {
                    case .none:
                        return
                    case .topMost:
                        dismissTopMostViewController(animated: true, completion: nil)
                    case .all:
                        dismissAllViewControllers(animated: true, completion: nil)
                    }
                }
            }
            .store(in: &cancellables)

        router.genericDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .sheet(view):
                    present(view)
                case let .fullScreen(view):
                    present(view, fullScreen: true)
                }
            }
            .store(in: &cancellables)
    }

    func handle(error: any Error) {
        logger.error(error)
        bannerManager.displayTopErrorMessage(error)
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

    func createEditVaultView(vault: Share?) {
        if let vault {
            presentCreateEditVaultView(mode: .editExistingVault(vault))
        } else {
            presentCreateEditVaultView(mode: .create)
        }
    }

    func presentManageSharedShare(with displayType: ManageSharedDisplay, dismissal: SheetDismissal) {
        let manageShareShareView =
            ManageSharedShareView(viewModel: ManageSharedShareViewModel(display: displayType))

        let completion: () -> Void = { [weak self] in
            guard let self else {
                return
            }
            if let host = rootViewController
                .topMostViewController as? UIHostingController<ManageSharedShareView> {
                /// Updating share data circumventing the onAppear not being called after a sheet presentation
                host.rootView.refresh()
                return
            }
            present(manageShareShareView)
        }

        switch dismissal {
        case .none:
            present(manageShareShareView)
        case .topMost:
            dismissTopMostViewController(animated: true, completion: completion)
        case .all:
            dismissAllViewControllers(animated: true, completion: completion)
        }
    }

    func presentAcceptRejectInvite(with invite: UserInvite) {
        let view = AcceptRejectInviteView(viewModel: AcceptRejectInviteViewModel(invite: invite))

        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(invite.isVault ? .medium : .custom(270),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentLogsView(for module: PassModule) {
        let view = LogsView(viewModel: .init(module: module))
        present(view)
    }

    func presentItemDetailView(for itemContent: ItemContent, asSheet: Bool, showSecurityIssues: Bool = false) {
        let coordinator = ItemDetailCoordinator(itemDetailViewModelDelegate: self)
        coordinator.showDetail(for: itemContent, asSheet: asSheet, showSecurityIssues: showSecurityIssues)
        itemDetailCoordinator = coordinator
        addNewEvent(type: .read(itemContent.type))
    }

    func presentPasswordReusedListView(for itemContent: ItemContent) {
        let view = PasswordReusedView(viewModel: .init(itemContent: itemContent))
        present(view, uniquenessTag: UniqueSheet.reusedPasswordList)
    }

    func presentEditItemView(for itemContent: ItemContent) {
        do {
            let coordinator = makeCreateEditItemCoordinator()
            try coordinator.presentEditOrCloneItemView(for: itemContent, isEdit: true)
        } catch {
            handle(error: error)
        }
    }

    func presentCloneItemView(for itemContent: ItemContent) {
        dismissAllViewControllers { [weak self] in
            guard let self else { return }
            do {
                let coordinator = makeCreateEditItemCoordinator()
                try coordinator.presentEditOrCloneItemView(for: itemContent, isEdit: false)
            } catch {
                handle(error: error)
            }
        }
    }

    func presentCreateItemView(for itemType: ItemType) {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let coordinator = makeCreateEditItemCoordinator()
                try await coordinator.presentCreateItemView(for: itemType) { [weak self] error in
                    guard let self else { return }
                    handle(error: error)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func presentCreateEditVaultView(mode: VaultMode) {
        let viewModel = CreateEditVaultViewModel(mode: mode)
        viewModel.delegate = self
        let view = CreateEditVaultView(viewModel: viewModel)
        present(view)
    }

    func presentShareElementView(for vault: VaultListUiModel, itemContent: ItemContent) {
        let viewModel = ShareElementViewModel(share: vault.vault,
                                              itemContent: itemContent,
                                              itemCount: vault.itemCount)
        let view = ShareElementView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        viewController.setDetentType(.medium,
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        viewModel.sheetPresentation = viewController.sheetPresentationController

        present(viewController)
    }

    func presentBulkPermanentDeleteConfirmation(itemCount: Int, aliasCount: Int) {
        let title: String
        let message: String
        let buttonTitle: String

        if aliasCount > 0 {
            title = #localized("You are about to permanently delete %lld aliases", aliasCount)
            message = #localized("Please note once deleted, the aliases can't be restored")
            buttonTitle = #localized("Understood, I will never need them")
        } else {
            title = #localized("Delete permanently?")
            message = #localized("You are going to delete %lld items irreversibly, are you sure?", itemCount)
            buttonTitle = #localized("Delete")
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: buttonTitle,
                                         style: .destructive) { [weak self] _ in
            guard let self else { return }
            itemsTabViewModel?.permanentlyDeleteSelectedItems()
        }
        alert.addAction(deleteAction)
        alert.addAction(.init(title: #localized("Cancel"), style: .cancel))
        present(alert)
    }

    func startUpgradeFlow() {
        dismissAllViewControllers(animated: true) { [weak self] in
            guard let self else { return }
            paymentsManager.manageSubscription(isUpgrading: true) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(result):
                    if result {
                        refreshAccessAndMonitorStateSync()
                    } else {
                        logger.debug("Payment is done but no plan is purchased")
                    }
                case let .failure(error):
                    handle(error: error)
                }
            }
        }
    }

    func startUpsellingFlow(configuration: UpsellingViewConfiguration, dismissal: SheetDismissal) {
        let view = UpsellingView(configuration: configuration) { [weak self] in
            guard let self else {
                return
            }
            startUpgradeFlow()
        }

        let completion: () -> Void = { [weak self] in
            guard let self else {
                return
            }
            let viewController = UIHostingController(rootView: view)

            viewController.sheetPresentationController?.prefersGrabberVisible = false
            present(viewController)
        }

        switch dismissal {
        case .none:
            present(view)
        case .topMost:
            dismissTopMostViewController(animated: true, completion: completion)
        case .all:
            dismissAllViewControllers(animated: true, completion: completion)
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

    func itemMoveBetweenVault(context: MovingContext) {
        let allVaults = appContentManager.getAllEditableVaultContents()
        guard !allVaults.isEmpty else {
            return
        }
        let viewModel = MoveVaultListViewModel(allVaults: allVaults, context: context)
        let view = MoveVaultListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = 66 * allVaults.count + 300
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentCreateSecureLinkView(for item: ItemContent, and share: Share) {
        let presentCreateSecureLinkView: () -> Void = { [weak self] in
            guard let self else { return }
            let viewModel = CreateSecureLinkViewModel(itemContent: item, share: share)
            let view = CreateSecureLinkView(viewModel: viewModel)
            let viewController = UIHostingController(rootView: view)
            viewController.setDetentType(.custom(CreateSecureLinkViewModelState.default.sheetHeight),
                                         parentViewController: rootViewController)
            viewController.sheetPresentationController?.prefersGrabberVisible = true
            viewModel.sheetPresentation = viewController.sheetPresentationController
            present(viewController)
        }
        dismissTopMostViewController(completion: presentCreateSecureLinkView)
    }

    func presentLoginsWith2faView() {
        let items = appContentManager.getAllActiveAndTrashedItems().filter { $0.totpUri?.isEmpty == false }
        present(LoginsWith2faView(viewModel: .init(items: items)))
    }

    func handleFailedLocalAuthentication(_ errorMessage: String?) {
        Task { [weak self] in
            guard let self else { return }
            logger.error("Failed to locally authenticate. Logging out.")
            showLoadingHud()
            await revokeCurrentSession()
            hideLoadingHud()
            delegate?.homepageCoordinatorDidFailLocallyAuthenticating(errorMessage)
        }
    }

    func presentChangePassword(mode: PasswordChangeModule.PasswordChangeMode) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let userData = try await userManager.getUnwrappedActiveUserData()
                let userInfo = try await filledUserInfo(userData: userData)
                let apiService = try apiManager.getApiService(userId: userData.user.ID)
                let viewController = PasswordChangeModule
                    .makePasswordChangeViewController(mode: mode,
                                                      apiService: apiService,
                                                      authCredential: userData.credential,
                                                      userInfo: userInfo,
                                                      showingDismissButton: true) { [weak self] cred, userInfo in
                        guard let self else { return }
                        processPasswordChange(authCredential: cred, userInfo: userInfo)
                    }
                let navigationController = UINavigationController(rootViewController: viewController)
                present(navigationController)
            } catch {
                handle(error: error)
            }
        }
    }

    func presentSecurityKeys() {
        Task { [weak self] in
            guard let self,
                  let userId = try? await userManager.getActiveUserId(),
                  let apiService = try? apiManager.getApiService(userId: userId) else { return }

            let viewController = LoginUIModule
                .makeSecurityKeysViewController(apiService: apiService,
                                                clientApp: .pass)
            let navigationController = UINavigationController(rootViewController: viewController)
            present(navigationController)
        }
    }

    func presentPasswordHistoryView() {
        let createLogin: (String) -> Void = { [weak self] clearPassword in
            guard let self else { return }
            dismissTopMostViewController(animated: true) { [weak self] in
                guard let self else { return }
                presentCreateEditLoginView(mode: .create(shareId: nil,
                                                         type: .login(password: clearPassword,
                                                                      autofill: false)))
            }
        }
        let view = PasswordHistoryView(repository: passwordHistoryRepository,
                                       onCreateLogin: createLogin,
                                       onCopy: { [weak self] password in
                                           guard let self else { return }
                                           copyToClipboard(password,
                                                           bannerMessage: #localized("Password copied"),
                                                           bannerDisplay: bannerManager)
                                       })
        present(view)
    }

    func presentSignInToAnotherDeviceView() {
        Task { @MainActor in
            do {
                guard let userId = userManager.activeUserId,
                      let authCredential = authManager.getCredential(userId: userId)
                else {
                    return
                }

                let passphrase = authCredential.mailboxpassword
                let email = try await (userManager.getActiveUserData()?.user.email) ?? ""
                let apiService = try apiManager.getApiService(userId: userId)

                let view = NavigationStackEmbededView(content: {
                    ScanQRCodeInstructionsView(viewModel: .init(dependencies: .init(passphrase: passphrase,
                                                                                    userEmail: email,
                                                                                    apiService: apiService)))
                }, toolbar: {
                    ToolbarItem(placement: .topBarLeading) {
                        CircleButton(icon: IconProvider.cross,
                                     iconColor: PassColor.interactionNormMajor2,
                                     backgroundColor: PassColor.interactionNormMinor1,
                                     accessibilityLabel: "Close",
                                     action: { [weak self] in
                                         guard let self else { return }
                                         dismissTopMostViewController(animated: true)
                                     })
                    }
                })

                present(view)
            } catch {
                handle(error: error)
            }
        }
    }

    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if UIDevice.current.isIpad {
            activityVC.popoverPresentationController?.sourceView = topMostViewController.view
        }
        present(activityVC)
    }

    private func filledUserInfo(userData: UserData) async throws -> UserInfo {
        let userId = try await userManager.getActiveUserId()
        let settings = await userSettingsRepository.getSettings(for: userId)
        let userInfo = userData.toUserInfo
        userInfo.twoFactor = settings.twoFactor.type.rawValue
        userInfo.passwordMode = settings.password.mode.rawValue
        return userInfo
    }

    private func processPasswordChange(authCredential: AuthCredential, userInfo: UserInfo) {
        Task { [weak self] in
            guard let self, let userData = try? await userManager.getActiveUserData() else { return }
            var updatedUser = userData.user
            updatedUser.setNewKeys(userInfo.userKeys)
            /*
             Passphrases need to be updated. To find the key of the passphrase that needs to be updated with the new passphrase we need to take a little detour, because core returns crap and does not tell us which one is the primary key. We need to find it ourselves.
             First we get the salt from the authCredential. With that we then find the corresponding salt in userData.salts. From there we extract the id of the user key for which that salt is used.
             This user key is the primary key.
             Since we now have the id of the primary key, we can go in the passphrases.
             Passprases store the user key id -> passphrase.
             We can now replace the passphrase for the primary key with confidence.
             */
            var passphrases = userData.passphrases
            if let passphraseSalt = authCredential.passwordKeySalt,
               let keyId = userData.salts.first(where: { $0.keySalt == passphraseSalt })?.ID {
                passphrases[keyId] = authCredential.mailboxpassword
            }

            // Also update the session encryption details in the auth manager so that the passphrase used by other
            // features like QR login, use the correct passphrase after a password reset.
            authManager.updateEncryptionDetailsForSession(sessionUID: authCredential.sessionID,
                                                          mailboxpassword: authCredential.mailboxpassword,
                                                          salt: authCredential.passwordKeySalt,
                                                          privateKey: authCredential.passwordKeySalt)

            try? await userManager.upsertAndMarkAsActive(userData: .init(credential: authCredential,
                                                                         user: updatedUser,
                                                                         salts: userData.salts,
                                                                         passphrases: passphrases,
                                                                         addresses: userInfo.userAddresses,
                                                                         scopes: userData.scopes))
            dismissTopMostViewController { [weak self] in
                guard let self else { return }
                bannerManager.displayBottomInfoMessage(#localized("Password changed successfully"))
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

    func present(_ view: some View,
                 animated: Bool = true,
                 dismissible: Bool = true,
                 fullScreen: Bool = false,
                 uniquenessTag: (any RawRepresentable<Int>)? = nil) {
        let vc = UIHostingController(rootView: view)
        if fullScreen {
            vc.modalPresentationStyle = .fullScreen
            vc.isModalInPresentation = true
        }
        present(vc,
                animated: animated,
                dismissible: dismissible,
                uniquenessTag: uniquenessTag)
    }

    func updateSharedPreferences<T: Sendable>(_ keyPath: WritableKeyPath<SharedPreferences, T>, value: T) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await preferencesManager.updateSharedPreferences(keyPath, value: value)
            } catch {
                handle(error: error)
            }
        }
    }

    func updateUserPreferences<T: Sendable>(_ keyPath: WritableKeyPath<UserPreferences, T>, value: T) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await preferencesManager.updateUserPreferences(keyPath, value: value)
            } catch {
                handle(error: error)
            }
        }
    }
}

// MARK: - Security Center

extension HomepageCoordinator {
    func presentSecurity(_ securityWeakness: SecurityWeakness) {
        let isSheet = shouldShowAsSheet()
        let results = (view: SecurityWeaknessDetailView(viewModel: .init(type: securityWeakness),
                                                        isSheet: isSheet),
                       isSheet: isSheet)

        if results.isSheet {
            present(results.view)
        } else {
            push(results.view)
        }
    }
}

// MARK: - Item history

extension HomepageCoordinator {
    func presentItemHistory(_ item: ItemContent) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let plan = try await accessRepository.getPlan(userId: nil)
                if plan.isFreeUser {
                    startUpsellingFlow(configuration: .default, dismissal: .all)
                } else {
                    let view = ItemHistoryView(viewModel: ItemHistoryViewModel(item: item))
                    present(view)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func updateAfterRestoration() {
        dismissTopMostViewController(animated: true, completion: nil)
        itemDetailCoordinator?.refresh()
    }
}

// MARK: - Open webpages

extension HomepageCoordinator {
    func beginAccountSettingsFlow() {
        do {
            let url = try makeAccountSettingsUrl()
            urlOpener.open(urlString: url)
        } catch {
            handle(error: error)
        }
    }

    func openTutorialVideo() {
        urlOpener.open(urlString: ProtonLink.youtubeTutorial)
    }
}

// MARK: - Coordinators

private extension HomepageCoordinator {
    func makeCreateEditItemCoordinator() -> CreateEditItemCoordinator {
        let coordinator = CreateEditItemCoordinator(createEditItemDelegates: self)
        createEditItemCoordinator = coordinator
        return coordinator
    }
}

// MARK: - Public APIs

extension HomepageCoordinator {
    func onboardIfNecessary() {
        Task { [weak self] in
            guard let self,
                  await loginMethod.isManualLogIn() else { return }
            if let access = try? await accessRepository.getAccess(userId: nil).access,
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
        let vc = UIHostingController(rootView: view)
        vc.modalPresentationStyle = UIDevice.current.isIpad ? .formSheet : .fullScreen
        vc.isModalInPresentation = true
        topMostViewController.present(vc, animated: true)
    }

    func presentOnboardView(forced: Bool) {
        guard forced || !getAppPreferences().onboarded else { return }
        let view = OnboardingView(handler: onboardingHandler)
        let vc = UIHostingController(rootView: view)
        vc.modalPresentationStyle = UIDevice.current.isIpad ? .formSheet : .fullScreen
        vc.isModalInPresentation = true
        topMostViewController.present(vc, animated: true)
    }

    func displayUndecryptableSharesBanner(_ dismissTopSheetBeforeShowing: Bool) {
        let learnMore: @Sendable (PMBanner) -> Void = { [weak self] banner in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }
                banner.dismiss()
                urlOpener.open(urlString: ProtonLink.recoverEncryptedData)
            }
        }
        let message =
            // swiftlint:disable:next line_length
            #localized("Some vaults are no longer accessible due to a password reset. Reactivate your account keys in order to regain access.")
        let displayBanner: () -> Void = { [weak self] in
            guard let self else { return }
            bannerManager.displayBottomErrorMessage(message,
                                                    dismissButtonTitle: #localized("Learn more"),
                                                    onDismiss: learnMore)
        }
        if dismissTopSheetBeforeShowing {
            dismissTopMostViewController(animated: true) {
                displayBanner()
            }
        } else {
            displayBanner()
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

    func childCoordinatorWantsToDismissTopViewController() {
        dismissTopMostViewController()
    }

    func childCoordinatorDidFailLocalAuthentication() {
        delegate?.homepageCoordinatorDidFailLocallyAuthenticating(nil)
    }
}

// MARK: - ItemsTabViewModelDelegate

extension HomepageCoordinator: ItemsTabViewModelDelegate {
    func itemsTabViewModelWantsToCreateNewItem(type: ItemContentType) {
        presentCreateItemView(for: type.type)
    }

    func itemsTabViewModelWantsToPresentVaultList() {
        let viewController = UIHostingController(rootView: EditableVaultListView())

        // Num of vaults + all items + trash + create vault button
        let rowHeight = 74
        let customHeight = rowHeight * appContentManager.getSharesCount() + (rowHeight * 4) + 120
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func itemsTabViewModelWantsViewDetail(of itemContent: ItemContent) {
        presentItemDetailView(for: itemContent, asSheet: shouldShowAsSheet())
    }
}

// MARK: - ProfileTabViewModelDelegate

extension HomepageCoordinator: ProfileTabViewModelDelegate {
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
        let errorHandler: (any Error) -> Void = { [weak self] error in
            guard let self else { return }
            handle(error: error)
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
}

// MARK: - AccountViewModelDelegate

extension HomepageCoordinator: AccountViewModelDelegate {
    func accountViewModelWantsToGoBack() {
        adaptivelyDismissCurrentDetailView()
    }

    func deleteAccount(userId: String) {
        guard let userId = userManager.activeUserId,
              let apiService = try? apiManager.getApiService(userId: userId)
        else {
            return
        }
        let accountDeletion = AccountDeletionService(api: apiService)
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
                                                                   loggingOutUser(userId: userId)
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

    func accountViewModelWantsToShowAccountRecovery(_ completion: @escaping (AccountRecovery) -> Void) {
        guard let userId = userManager.activeUserId,
              let apiService = try? apiManager.getApiService(userId: userId)
        else {
            return
        }
        let asSheet = shouldShowAsSheet()
        let viewModel = AccountRecoveryView
            .ViewModel(accountRepository: AccountRecoveryRepository(apiService: apiService))
        viewModel.externalAccountRecoverySetter = { accountRecovery in
            completion(accountRecovery)
        }

        let view = AccountRecoveryView(viewModel: viewModel)
        showView(view: view, asSheet: asSheet)
    }
}

// MARK: - SettingsViewModelDelegate

extension HomepageCoordinator: SettingsViewModelDelegate {
    func settingsViewModelWantsToGoBack() {
        adaptivelyDismissCurrentDetailView()
    }

    func settingsViewModelWantsToEditDefaultBrowser() {
        let currentValue = getSharedPreferences().browser
        let view = EditDefaultBrowserView(selection: currentValue) { [weak self] newValue in
            guard let self else { return }
            updateSharedPreferences(\.browser, value: newValue)
        }
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * Browser.allCases.count + 100
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func settingsViewModelWantsToEditTheme() {
        let theme = getSharedPreferences().theme
        let view = EditThemeView(currentTheme: theme) { [weak self] newTheme in
            guard let self else { return }
            updateSharedPreferences(\.theme, value: newTheme)
        }
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.short.value) * Theme.allCases.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func settingsViewModelWantsToEditClipboardExpiration() {
        let currentValue = getSharedPreferences().clipboardExpiration
        let view = EditClipboardExpirationView(selection: currentValue) { [weak self] newValue in
            guard let self else { return }
            updateSharedPreferences(\.clipboardExpiration, value: newValue)
        }
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * ClipboardExpiration.allCases.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func settingsViewModelWantsToClearLogs() {
        Task { [weak self] in
            guard let self else {
                return
            }
            let modules = PassModule.allCases.map(LogManager.init)
            await modules.asyncForEach { await $0.removeAllLogs() }
            bannerManager.displayBottomSuccessMessage(#localized("All logs cleared"))
        }
    }
}

// MARK: - GeneratePasswordCoordinatorDelegate

extension HomepageCoordinator: GeneratePasswordCoordinatorDelegate {
    func generatePasswordCoordinatorWantsToPresent(viewController: UIViewController) {
        present(viewController)
    }
}

extension HomepageCoordinator {
    func presentSetPINCodeView() {
        dismissTopMostViewController { [weak self] in
            guard let self else { return }
            present(SetPINCodeView())
        }
    }
}

extension HomepageCoordinator {
    func handleItemCreation(item: SymmetricallyEncryptedItem, type: ItemContentType) {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
                let itemContent = try item.getItemContent(symmetricKey: symmetricKey)
                let displayToastMessage: () -> Void = { [weak self] in
                    guard let self else { return }
                    if appContentManager.isItemVisible(item, type: type) {
                        bannerManager.displayBottomInfoMessage(type.creationMessage)
                    } else {
                        bannerManager.displayBottomInfoMessage(type.creationMessage,
                                                               dismissButtonTitle: type
                                                                   .openMessage) { [weak self] _ in
                            guard let self else { return }
                            router.present(for: .itemDetail(itemContent))
                        }
                    }
                }

                addNewEvent(type: .create(type))
                dismissAllViewControllers(animated: true) {
                    // We have eventual crashes after creating items
                    // Looks like it's because the keyboard is not fully dismissed
                    // and in between we try to show a banner
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        displayToastMessage()
                    }
                }
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.refresh(userId: userId)
                homepageTabDelegate?.change(tab: .items)
                increaseCreatedItemsCountAndAskForReviewIfNecessary()
            } catch {
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType, updated: Bool) {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                guard updated else {
                    dismissTopMostViewController()
                    return
                }
                addNewEvent(type: .update(type))
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.refresh(userId: userId)
                itemDetailCoordinator?.refresh()
                dismissTopMostViewController { [weak self] in
                    guard let self else { return }
                    bannerManager.displayBottomInfoMessage(type.updateMessage)
                }
            } catch {
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }
}

// MARK: - CreateEditLoginViewModelDelegate

extension HomepageCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: any AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options, creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium()]
        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: any GeneratePasswordViewModelDelegate) {
        let coordinator = makeCreateEditItemCoordinator()
        coordinator.presentGeneratePasswordForLoginItem(delegate: delegate)
    }
}

// MARK: - GeneratePasswordViewModelDelegate

extension HomepageCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        dismissTopMostViewController(animated: true) { [weak self] in
            guard let self else { return }
            let viewPasswordHistory: @Sendable (PMBanner) -> Void = { [weak self] banner in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }
                    banner.dismiss()
                    presentPasswordHistoryView()
                }
            }
            bannerManager.displayBottomInfoMessage(#localized("Password copied"),
                                                   dismissButtonTitle: #localized("View"),
                                                   onDismiss: viewPasswordHistory)
            copyToClipboard(password)
        }
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

    func itemDetailViewModelWantsToShowFullScreen(_ data: FullScreenData) {
        showFullScreen(data: data)
    }
}

// MARK: - CreateEditVaultViewModelDelegate

extension HomepageCoordinator: CreateEditVaultViewModelDelegate {
    func createEditVaultViewModelDidEditVault() {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                dismissTopMostViewController(animated: true) { [weak self] in
                    guard let self else { return }
                    bannerManager.displayBottomInfoMessage(#localized("Vault updated"))
                }
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.refresh(userId: userId)
            } catch {
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }
}

// MARK: - SyncEventLoopDelegate

extension HomepageCoordinator: SyncEventLoopDelegate {
    nonisolated func syncEventLoopDidStartLooping() {
        logger.info("Started looping")
    }

    nonisolated func syncEventLoopDidStopLooping() {
        logger.info("Stopped looping")
    }

    nonisolated func syncEventLoopDidBeginNewLoop(userId: String) {
        logger.info("Began new sync loop for userId \(userId)")
    }

    func syncEventLoopShouldUseUserEvents() async -> Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passUserEventsV1)
    }

    nonisolated func syncEventLoopDidSkipLoop(reason: SyncEventLoopSkipReason) {
        logger.info("Skipped sync loop \(reason)")
    }

    func syncEventLoopRequiresFullSync(userId: String) async throws {
        router.present(for: .fullSync)
        logger.info("Full syncing triggered by user events")
        await fullContentSync(userId: userId, shouldStopEventLoop: false)
        logger.info("Done full syncing triggered by user events")
        router.display(element: .successMessage(config: .refresh))
    }

    nonisolated func syncEventLoopDidFinishLoop(userId: String, hasNewEvents: Bool) {
        if hasNewEvents {
            logger.info("Has new events. Refreshing items for userId \(userId)")
            Task { [weak self] in
                guard let self else {
                    return
                }

                await refresh(exitEditMode: false)
            }
        } else {
            logger.info("Has no new events for userId \(userId). Do nothing.")
        }
    }

    nonisolated func syncEventLoopDidFailLoop(userId: String, error: any Error) {
        // Silently fail & not show error to users
        logger.error(message: "User \(userId)", error: error)
    }

    nonisolated func syncEventLoopDidBeginExecutingAdditionalTask(userId: String, label: String) {
        logger.trace("Began executing additional task \(label) for userId \(userId)")
    }

    nonisolated func syncEventLoopDidFinishAdditionalTask(userId: String, label: String) {
        logger.info("Finished executing additional task \(label) for userId \(userId)")
    }

    nonisolated func syncEventLoopDidFailedAdditionalTask(userId: String, label: String, error: any Error) {
        logger.error(message: "Failed to execute additional task \(label) for userId \(userId)", error: error)
    }
}

private extension HomepageCoordinator {
    func parseNavigationConfig(config: NavigationConfiguration?) {
        guard let config else {
            return
        }
        if let event = config.telemetryEvent {
            addNewEvent(type: event)

            if case .delete = event {
                itemDetailCoordinator = nil
            }
        }

        if config.refresh {
            refresh()
        }

        if config.dismissBeforeShowing {
            window?.endEditing(true)
        }
    }
}
