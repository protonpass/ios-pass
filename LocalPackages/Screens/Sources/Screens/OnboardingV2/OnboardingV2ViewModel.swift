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

enum OnboardV2Step: Sendable {
    case payment, biometric(BiometricType), autofill
}

@MainActor
final class OnboardingV2ViewModel: ObservableObject {
    @Published private(set) var currentStep: OnboardV2Step
    @Published private(set) var finished = false
    private let availableBiometricType: BiometricType?

    init(isFreeUser: Bool,
         availableBiometricType: BiometricType?) {
        if isFreeUser {
            currentStep = .payment
        } else if let availableBiometricType {
            currentStep = .biometric(availableBiometricType)
        } else {
            currentStep = .autofill
        }
        self.availableBiometricType = availableBiometricType
    }
}

extension OnboardingV2ViewModel {
    /// Returns `true` if other steps are available,
    /// `false` if no more steps so the onboarding process could be ended
    func goNext() -> Bool {
        switch currentStep {
        case .payment:
            if let availableBiometricType {
                currentStep = .biometric(availableBiometricType)
            } else {
                currentStep = .autofill
            }
            return true

        case .biometric:
            currentStep = .autofill
            return true

        case .autofill:
            return false
        }
    }

    func performCta() {
        if !goNext() {
            finished = true
        }
    }
}
