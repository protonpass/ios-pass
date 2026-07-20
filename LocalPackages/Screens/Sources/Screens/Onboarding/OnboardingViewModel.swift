//
// OnboardingViewModel.swift
// Proton Pass - Created on 28/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Core
import DIComposition
import Entities
import FactoryKit
import Foundation
import LocalAuthentication
import Macro
import ProtonCorePaymentsUIV2
import ProtonCorePaymentsV2
import StoreKit

// periphery:ignore
public enum OnboardFirstLoginSuggestion: Sendable {
    case none
    case suggestedShare(shareId: String)
}

nonisolated struct OnboardFirstLoginPayload: Equatable {
    let shareId: String
    let service: KnownService
    let title: String
    let email: String
    let username: String
    let password: String
    let website: String

    var emailOrUsername: String {
        email.isEmpty ? username : email
    }
}

nonisolated struct KnownService: Decodable, Equatable {
    let name: String
    let url: String
    let favIconUrl: String
    let loginType: LoginType

    enum LoginType: String, Decodable {
        case email, username, both
    }
}

// public typealias OnboardingHandling = OnboardingDatasource & OnboardingDelegate

nonisolated struct PassPlans: Equatable {
    let foldersEnabled: Bool
    let plus: PlanUiModel?
    let unlimited: PlanUiModel?

    var noPlansAvailable: Bool {
        plus == nil && unlimited == nil
    }

    var onePlanAvailable: Bool {
        (plus == nil && unlimited != nil) || (plus != nil && unlimited == nil)
    }
}

nonisolated enum OnboardStep: Equatable {
    case payment(PassPlans)
    case biometric(LABiometryType)
    case autofill
    case aliasExplanation
    case createFirstLogin(shareId: String, [KnownService])
    case firstLoginCreated(OnboardFirstLoginPayload)
}

public enum OnboardingDisplayMode: Equatable {
    case onboarding
    case upsell
}

@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var currentStep: FetchableObject<OnboardStep> = .fetching
    private(set) var isPurchasing = false
    private(set) var isSaving = false
    private(set) var finished = false
    private(set) var shouldDismiss = false
    var selectedPlan: PlanUiModel?
    private var availableBiometryType: LABiometryType?

    private let preferencesManager = dependency(\ToolingContainer.preferencesManager)
    private let credentialManager = dependency(\ServiceContainer.credentialManager)
    private let userManager = dependency(\ServiceContainer.userManager)
    private let accessRepository = dependency(\RepositoryContainer.accessRepository)
    private let checkBiometryType = dependency(\UseCasesContainer.checkBiometryType)
    private let localAuthenticationEnablingPolicy = dependency(\ToolingContainer.localAuthenticationEnablingPolicy)
    private let enableAutoFillUseCase = dependency(\UseCasesContainer.enableAutoFill)
    private let authenticateBiometrically = dependency(\UseCasesContainer.authenticateBiometrically)
    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
    private let addTelemetryEvent = dependency(\UseCasesContainer.addTelemetryEvent)
    private let apiManager = dependency(\ToolingContainer.apiManager)
    private let getFeatureFlagStatus = dependency(\UseCasesContainer.getFeatureFlagStatus)

    private let transactionsObserver: TransactionsObserverProviding
    private var plansManager: ProtonPlansManager?
    private let logger: Logger
    private let userDefaults: UserDefaults

    let mode: OnboardingDisplayMode

    init(mode: OnboardingDisplayMode,
         logManager: any LogManagerProtocol = ToolingContainer.shared.logManager(),
         userDefaults: UserDefaults = kSharedUserDefaults,
         transactionsObserver: TransactionsObserverProviding = TransactionsObserver.shared) {
        self.mode = mode
        logger = .init(manager: logManager)
        self.userDefaults = userDefaults
        self.transactionsObserver = transactionsObserver
    }
}

extension OnboardingViewModel {
    func setUp() async {
        do {
            availableBiometryType = try getBiometryType()
            let plans = try await getPassPlans()

            // When onboarding, we skip payment step when there's no plans.
            // When upselling (users hit by paywall)
            // we show payment step regardless of whether plans are available.
            // If not availble we show a message to redirect users to web
            let showPaymentStep = mode == .upsell || (mode == .onboarding && !plans.noPlansAvailable)

            if showPaymentStep {
                currentStep = .fetched(.payment(plans))
            } else if let availableBiometryType, availableBiometryType != .none, mode == .onboarding {
                currentStep = .fetched(.biometric(availableBiometryType))
            } else if mode == .onboarding {
                currentStep = .fetched(.autofill)
            }
        } catch {
            currentStep = .error(error)
        }
    }

    /// Returns `true` if other steps are available,
    /// `false` if no more steps so the onboarding process could be ended
    /// `isManual` means triggered by user (manually skip the step)
    func goNext(isManual: Bool = false) async -> Bool {
        guard mode == .onboarding else {
            shouldDismiss = true
            return false
        }

        guard let step = currentStep.fetchedObject else {
            assertionFailure("Current step is not initialized")
            return false
        }

        switch step {
        case .payment:
            if isManual {
                add(event: .onboardingUpsellSkipped)
            }
            if let availableBiometryType, availableBiometryType != .none {
                currentStep = .fetched(.biometric(availableBiometryType))
            } else {
                currentStep = .fetched(.autofill)
            }
            return true

        case .biometric:
            if isManual {
                add(event: .onboardingBiometricsSkipped)
            }
            if await isAutoFillEnabled() {
                // swiftlint:disable:next fallthrough
                fallthrough
            } else {
                currentStep = .fetched(.autofill)
                return true
            }

        case .autofill:
            if isManual {
                add(event: .onboardingPassAsAutofillProviderSkipped)
            }
            // Reenable when supporting creating first login
            /*
             switch await datasource.getFirstLoginSuggestion() {
             case .none:
                 return false
             case let .suggestedShare(shareId):
                 do {
                     let services = try fetchKnownServices()
                     currentStep = .fetched(.createFirstLogin(shareId: shareId, services))
                     return true
                 } catch {
                     currentStep = .error(error)
                     return false
                 }
             }
              */
            currentStep = .fetched(.aliasExplanation)
            return true

        case .aliasExplanation, .createFirstLogin, .firstLoginCreated:
            return false
        }
    }

    func performCta() async {
        var shouldGoToNextStep = false
        do {
            switch currentStep.fetchedObject {
            case .payment:
                // Not applicable because payment step has custom CTA button
                shouldGoToNextStep = true

            case .biometric:
                add(event: .onboardingBiometricsEnabled)
                try await enableBiometric()
                shouldGoToNextStep = true

            case .autofill:
                add(event: .onboardingPassAsAutofillProviderEnabled)
                shouldGoToNextStep = await enableAutoFill()

            case .aliasExplanation:
                await markAsOnboarded()
                finished = true
                return

            default:
                shouldGoToNextStep = true
            }
        } catch {
            handle(error: error)
        }

        if shouldGoToNextStep, await !goNext() {
            await markAsOnboarded()
            finished = true
        }
    }

    func performSecondaryCta() {
        if case .aliasExplanation = currentStep.fetchedObject {
            add(event: .onboardingAliasVideoOpened)
            openTutorialVideo()
            finished = true
        } else {
            assertionFailure("Missing secondary action")
        }
    }

    func createFirstLogin(payload: OnboardFirstLoginPayload) {
        defer { isSaving = false }
        isSaving = true
        // swiftlint:disable:next todo
        // TODO: implement login item creation when needed
        currentStep = .fetched(.firstLoginCreated(payload))
    }

    func purchaseSelectedPlan() {
        guard let selectedPlan else { return }
        Task { [weak self] in
            guard let self else { return }
            defer { isPurchasing = false }
            isPurchasing = true
            do {
                let plan = try await getCurrentPlan()
                add(event: .onboardingUpsellCtaClicked(planName: plan.internalName))
                try await purchase(selectedPlan.plan)
                add(event: .onboardingUpsellSubscribed)
                _ = await goNext()
            } catch {
                handle(error: error)
            }
        }
    }
}

extension OnboardingViewModel {
    func purchase(_ plan: ComposedPlan) async throws {
        guard let manager = try await getPlansManager() else { return }

        guard let product = plan.product as? Product else {
            assertionFailure("Failed to parse product")
            return
        }
        _ = try await manager.purchase(product)
        try await accessRepository.refreshAccess(userId: nil)
    }

    func enableBiometric() async throws {
        let authenticated = try await authenticateBiometrically(policy: localAuthenticationEnablingPolicy,
                                                                reason: #localized("Please authenticate"))
        if authenticated {
            try await preferencesManager.updateSharedPreferences(\.localAuthenticationMethod,
                                                                 value: .biometric)
        }
    }

    func enableAutoFill() async -> Bool {
        let outcome = await enableAutoFillUseCase()
        if outcome.needsInstructions {
            router.present(for: .autoFillInstructions)
        }
        return outcome.handled
    }

    func openTutorialVideo() {
        router.navigate(to: .urlPage(urlString: ProtonLink.youtubeTutorial))
    }

    func markAsOnboarded() async {
        // Optionally update "onboarded" to not block users from using the app
        // in case errors happens
        try? await preferencesManager.updateAppPreferences(\.onboarded, value: true)
    }

    func add(event: TelemetryEventType) {
        addTelemetryEvent(with: event)
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

extension OnboardingViewModel {
    func getCurrentPlan() async throws -> Entities.Plan {
        try await accessRepository.getPlan(userId: nil)
    }

    func getPassPlans() async throws -> PassPlans {
        guard !Bundle.main.isBetaBuild, let manager = try await getPlansManager() else {
            return .init(foldersEnabled: false, plus: nil, unlimited: nil)
        }
        let plans = try await manager.getAvailablePlans()
        let plusId = "iospass_pass2023_12_usd_auto_renewing"
        let unlimitedId = "iospass_bundle2022_12_usd_auto_renewing"

        var plusPlan: PlanUiModel?
        var unlimitedPlan: PlanUiModel?

        if let plusComposedPlan = plans.first(where: { $0.product.id == plusId }) {
            plusPlan = PlanUiModel(plan: plusComposedPlan)
        }

        if let unlimitedComposedPlan = plans.first(where: { $0.product.id == unlimitedId }) {
            unlimitedPlan = PlanUiModel(plan: unlimitedComposedPlan)
        }

        if Bundle.main.isQaBuild {
            if userDefaults.bool(forKey: Constants.QA.hidePassPlusPlan) {
                plusPlan = nil
            }

            if userDefaults.bool(forKey: Constants.QA.hideProtonUnlimitedPlan) {
                unlimitedPlan = nil
            }
        }

        let foldersEnabled = getFeatureFlagStatus(for: FeatureFlagType.passFolder)
        return .init(foldersEnabled: foldersEnabled,
                     plus: plusPlan,
                     unlimited: unlimitedPlan)
    }

    func getBiometryType() throws -> LABiometryType? {
        try checkBiometryType(policy: localAuthenticationEnablingPolicy)
    }

    func isAutoFillEnabled() async -> Bool {
        await credentialManager.isAutoFillEnabled
    }

    // periphery:ignore
    func getFirstLoginSuggestion() -> OnboardFirstLoginSuggestion {
        .none
    }
}

private extension OnboardingViewModel {
    // periphery:ignore
    func fetchKnownServices() throws -> [KnownService] {
        guard let url = Bundle.module.url(forResource: "Top100services",
                                          withExtension: "json") else {
            assertionFailure("Failed to load list of known services")
            return []
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([KnownService].self, from: data)
    }

    func getPlansManager() async throws -> ProtonPlansManager? {
        if let plansManager {
            return plansManager
        }

        let userId = try await userManager.getActiveUserId()
        let apiService = try apiManager.getApiService(userId: userId)
        let remoteManager = RemoteManager(apiService: apiService)
        let configuration = TransactionsObserverConfiguration(remoteManager: remoteManager)
        transactionsObserver.setConfiguration(configuration)
        try await transactionsObserver.start()
        let manager = ProtonPlansManager(remoteManager: remoteManager)
        plansManager = manager
        return manager
    }
}
