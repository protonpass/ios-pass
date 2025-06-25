//
// OnboardingV2ViewModel.swift
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

import Entities
import Foundation
import LocalAuthentication
import ProtonCorePaymentsV2
import StoreKit

// periphery:ignore
public enum OnboardFirstLoginSuggestion: Sendable {
    case none
    case suggestedShare(shareId: String)
}

public struct OnboardFirstLoginPayload: Sendable, Equatable {
    public let shareId: String
    public let service: KnownService
    public let title: String
    public let email: String
    public let username: String
    public let password: String
    public let website: String

    var emailOrUsername: String {
        email.isEmpty ? username : email
    }
}

public struct KnownService: Sendable, Decodable, Equatable {
    let name: String
    let url: String
    let favIconUrl: String
    let loginType: LoginType

    enum LoginType: String, Sendable, Decodable {
        case email, username, both
    }
}

public typealias OnboardingV2Handling = OnboardingV2Datasource & OnboardingV2Delegate

public struct PassPlans: Sendable, Equatable {
    let plus: PlanUiModel
    let unlimited: PlanUiModel

    public init(plus: PlanUiModel, unlimited: PlanUiModel) {
        self.plus = plus
        self.unlimited = unlimited
    }
}

public protocol OnboardingV2Datasource: Sendable, AnyObject {
    func getCurrentPlan() async throws -> Entities.Plan
    func getPassPlans() async throws -> PassPlans?
    func getBiometryType() async throws -> LABiometryType?
    func isAutoFillEnabled() async -> Bool
    // periphery:ignore
    func getFirstLoginSuggestion() async -> OnboardFirstLoginSuggestion
}

public protocol OnboardingV2Delegate: Sendable, AnyObject {
    func purchase(_ plan: ComposedPlan) async throws
    func enableBiometric() async throws
    func enableAutoFill() async -> Bool
    func openTutorialVideo() async
    // periphery:ignore
    func createFirstLogin(payload: OnboardFirstLoginPayload) async throws
    func markAsOnboarded() async
    func add(event: TelemetryEventType) async
    func handle(error: any Error) async
}

enum OnboardV2Step: Sendable, Equatable {
    case payment(PassPlans)
    case biometric(LABiometryType)
    case autofill
    case aliasExplanation
    case createFirstLogin(shareId: String, [KnownService])
    case firstLoginCreated(OnboardFirstLoginPayload)
}

@MainActor
final class OnboardingV2ViewModel: ObservableObject {
    @Published private(set) var currentStep: FetchableObject<OnboardV2Step> = .fetching
    @Published private(set) var isPurchasing = false
    @Published private(set) var isSaving = false
    @Published private(set) var finished = false
    @Published var selectedPlan: PlanUiModel?
    private var availableBiometryType: LABiometryType?

    private weak var datasource: (any OnboardingV2Datasource)?
    private weak var delegate: (any OnboardingV2Delegate)?

    init(handler: OnboardingV2Handling?) {
        datasource = handler
        delegate = handler
    }
}

extension OnboardingV2ViewModel {
    func setUp() async {
        do {
            guard let datasource else {
                currentStep = .fetched(.autofill)
                return
            }

            availableBiometryType = try await datasource.getBiometryType()

            if let plans = try await datasource.getPassPlans() {
                currentStep = .fetched(.payment(plans))
            } else if let availableBiometryType, availableBiometryType != .none {
                currentStep = .fetched(.biometric(availableBiometryType))
            } else {
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
        guard let delegate, let datasource else { return false }

        guard let step = currentStep.fetchedObject else {
            assertionFailure("Current step is not initialized")
            return false
        }

        switch step {
        case .payment:
            if isManual {
                await delegate.add(event: .onboardingUpsellSkipped)
            }
            if let availableBiometryType, availableBiometryType != .none {
                currentStep = .fetched(.biometric(availableBiometryType))
            } else {
                currentStep = .fetched(.autofill)
            }
            return true

        case .biometric:
            if isManual {
                await delegate.add(event: .onboardingBiometricsSkipped)
            }
            if await datasource.isAutoFillEnabled() {
                // swiftlint:disable:next fallthrough
                fallthrough
            } else {
                currentStep = .fetched(.autofill)
                return true
            }

        case .autofill:
            if isManual {
                await delegate.add(event: .onboardingPassAsAutofillProviderSkipped)
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
        guard let delegate else { return }

        var shouldGoToNextStep = false
        do {
            switch currentStep.fetchedObject {
            case .payment:
                // Not applicable because payment step has custom CTA button
                shouldGoToNextStep = true

            case .biometric:
                await delegate.add(event: .onboardingBiometricsEnabled)
                try await delegate.enableBiometric()
                shouldGoToNextStep = true

            case .autofill:
                await delegate.add(event: .onboardingPassAsAutofillProviderEnabled)
                shouldGoToNextStep = await delegate.enableAutoFill()

            case .aliasExplanation:
                await delegate.markAsOnboarded()
                finished = true
                return

            default:
                shouldGoToNextStep = true
            }
        } catch {
            await delegate.handle(error: error)
        }

        if shouldGoToNextStep, await !goNext() {
            await delegate.markAsOnboarded()
            finished = true
        }
    }

    func performSecondaryCta() {
        Task { [weak self] in
            guard let self, let delegate else { return }
            if case .aliasExplanation = currentStep.fetchedObject {
                await delegate.add(event: .onboardingAliasVideoOpened)
                await delegate.openTutorialVideo()
                finished = true
            } else {
                assertionFailure("Missing secondary action")
            }
        }
    }

    func createFirstLogin(payload: OnboardFirstLoginPayload) {
        Task { [weak self] in
            guard let self else { return }
            defer { isSaving = false }
            isSaving = true
            do {
                try await delegate?.createFirstLogin(payload: payload)
                currentStep = .fetched(.firstLoginCreated(payload))
            } catch {
                await delegate?.handle(error: error)
            }
        }
    }

    func purchaseSelectedPlan() {
        guard let selectedPlan else { return }
        Task { [weak self] in
            guard let self, let delegate, let datasource else { return }
            defer { isPurchasing = false }
            isPurchasing = true
            do {
                let plan = try await datasource.getCurrentPlan()
                await delegate.add(event: .onboardingUpsellCtaClicked(planName: plan.internalName))
                try await delegate.purchase(selectedPlan.plan)
                await delegate.add(event: .onboardingUpsellSubscribed)
                _ = await goNext()
            } catch {
                await delegate.handle(error: error)
            }
        }
    }
}

private extension OnboardingV2ViewModel {
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
}
