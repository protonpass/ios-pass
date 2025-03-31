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

public protocol OnboardingV2Datasource: Sendable, AnyObject {
    func getAvailablePlans() async throws -> [PlanUiModel]
}

enum OnboardV2Step: Sendable, Equatable {
    case payment([PlanUiModel]), biometric(BiometricType), autofill
}

@MainActor
final class OnboardingV2ViewModel: ObservableObject {
    @Published private(set) var currentStep: FetchableObject<OnboardV2Step> = .fetching
    @Published private(set) var finished = false
    @Published var selectedPlan: PlanUiModel?
    private let isFreeUser: Bool
    private let availableBiometricType: BiometricType?

    private weak var datasource: (any OnboardingV2Datasource)?

    init(isFreeUser: Bool,
         availableBiometricType: BiometricType?,
         datasource: (any OnboardingV2Datasource)?) {
        self.isFreeUser = isFreeUser
        self.availableBiometricType = availableBiometricType
        self.datasource = datasource
    }
}

extension OnboardingV2ViewModel {
    func setUp() async {
        do {
            if isFreeUser {
                guard let datasource else {
                    assertionFailure("Datasource not set")
                    currentStep = .fetched(.autofill)
                    return
                }
                var plans = try await datasource.getAvailablePlans()
                plans = plans.sorted { $0.recurrence > $1.recurrence }
                assert(plans.count == 2, "Must have exactly 2 plans")
                assert(plans.first?.recurrence == .yearly, "Yearly plan must be the first")
                assert(plans.last?.recurrence == .monthly, "Montly plan must be the second")
                selectedPlan = plans.first
                currentStep = .fetched(.payment(plans))
            } else if let availableBiometricType {
                currentStep = .fetched(.biometric(availableBiometricType))
            } else {
                currentStep = .fetched(.autofill)
            }
        } catch {
            currentStep = .error(error)
        }
    }

    /// Returns `true` if other steps are available,
    /// `false` if no more steps so the onboarding process could be ended
    func goNext() -> Bool {
        switch currentStep.fetchedObject {
        case .payment:
            if let availableBiometricType {
                currentStep = .fetched(.biometric(availableBiometricType))
            } else {
                currentStep = .fetched(.autofill)
            }
            return true

        case .biometric:
            currentStep = .fetched(.autofill)
            return true

        case .autofill:
            return false

        default:
            return false
        }
    }

    func performCta() {
        if !goNext() {
            finished = true
        }
    }
}
