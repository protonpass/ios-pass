//
// OnboardingViewModel.swift
// Proton Pass - Created on 08/12/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Factory
import LocalAuthentication
import Macro
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var finished = false
    @Published private(set) var state = OnboardingViewState.autoFill

    private let credentialManager = resolve(\SharedServiceContainer.credentialManager)
    private let bannerManager = resolve(\SharedViewContainer.bannerManager)
    private let policy = resolve(\SharedToolingContainer.localAuthenticationEnablingPolicy)
    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)
    private let checkBiometryType = resolve(\SharedUseCasesContainer.checkBiometryType)
    private let authenticate = resolve(\SharedUseCasesContainer.authenticateBiometrically)
    private let openAutoFillSettings = resolve(\UseCasesContainer.openAutoFillSettings)

    private var cancellables = Set<AnyCancellable>()

    init() {
        checkAutoFillStatus()

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                checkAutoFillStatus()
            }
            .store(in: &cancellables)

        preferencesManager
            .sharedPreferencesUpdates
            .filter(\.localAuthenticationMethod)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self, newValue == .biometric else { return }
                do {
                    let biometryType = try checkBiometryType(policy: policy)
                    switch biometryType {
                    case .touchID:
                        state = .touchIDEnabled
                    default:
                        state = .faceIDEnabled
                    }
                } catch {
                    state = .faceIDEnabled
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Public actions

extension OnboardingViewModel {
    func primaryAction() {
        switch state {
        case .autoFill:
            openAutoFillSettings()

        case .autoFillEnabled:
            showAppropriateBiometricAuthenticationStep()

        case .biometricAuthenticationFaceID, .biometricAuthenticationTouchID:
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let authenticated = try await authenticate(policy: policy,
                                                               reason: #localized("Please authenticate"))
                    if authenticated {
                        try await preferencesManager.updateSharedPreferences(\.localAuthenticationMethod,
                                                                             value: .biometric)
                        showAppropriateBiometricAuthenticationStep()
                    }
                } catch {
                    bannerManager.displayTopErrorMessage(error)
                }
            }

        case .faceIDEnabled, .touchIDEnabled:
            state = .aliases

        case .aliases:
            finishOnboarding()
        }
    }

    func secondaryAction() {
        switch state {
        case .autoFill, .autoFillEnabled:
            showAppropriateBiometricAuthenticationStep()

        case .biometricAuthenticationFaceID,
             .biometricAuthenticationTouchID,
             .faceIDEnabled,
             .touchIDEnabled:
            state = .aliases

        case .aliases:
            finishOnboarding()
        }
    }
}

// MARK: - Private actions

private extension OnboardingViewModel {
    func checkAutoFillStatus() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let autoFillEnabled = await credentialManager.isAutoFillEnabled
            if case .autoFill = state, autoFillEnabled {
                state = .autoFillEnabled
            }
        }
    }

    func finishOnboarding() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Optionally update "onboarded" to not block users from using the app
            // in case errors happens
            try? await preferencesManager.updateAppPreferences(\.onboarded, value: true)
            finished = true
        }
    }

    func showAppropriateBiometricAuthenticationStep() {
        do {
            let preferences = preferencesManager.sharedPreferences.unwrapped()
            let biometryType = try checkBiometryType(policy: policy)
            switch biometryType {
            case .faceID:
                if preferences.localAuthenticationMethod == .biometric {
                    state = .faceIDEnabled
                } else {
                    state = .biometricAuthenticationFaceID
                }
            case .touchID:
                if preferences.localAuthenticationMethod == .biometric {
                    state = .touchIDEnabled
                } else {
                    state = .biometricAuthenticationTouchID
                }
            default:
                state = .aliases
            }
        } catch {
            state = .aliases
        }
    }
}
