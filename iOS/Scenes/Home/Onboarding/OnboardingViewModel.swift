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
import Core
import SwiftUI
import UIComponents

final class OnboardingViewModel: ObservableObject {
    @Published private(set) var finished = false
    @Published private(set) var state = OnboardingViewState.autoFill

    private let credentialManager: CredentialManagerProtocol
    private let preferences: Preferences
    private let biometricAuthenticator: BiometricAuthenticator
    private let bannerManager: BannerManager
    private var cancellables = Set<AnyCancellable>()

    init(credentialManager: CredentialManagerProtocol,
         preferences: Preferences,
         bannerManager: BannerManager,
         logManager: LogManager) {
        self.credentialManager = credentialManager
        self.preferences = preferences
        self.biometricAuthenticator = .init(preferences: preferences, logManager: logManager)
        self.bannerManager = bannerManager

        biometricAuthenticator.initializeBiometryType()
        checkAutoFillStatus()

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkAutoFillStatus()
            }
            .store(in: &cancellables)

        preferences.objectWillChange
            .sink { [weak self] _ in
                guard let self else { return }
                if self.preferences.biometricAuthenticationEnabled,
                    case .biometricAuthentication = self.state {
                    self.state = .biometricAuthenticationEnabled
                }
            }
            .store(in: &cancellables)

        biometricAuthenticator.$authenticationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                if case .error(let error) = state {
                    self.bannerManager.displayTopErrorMessage(error)
                }
            }
            .store(in: &cancellables)
    }

    private func checkAutoFillStatus() {
        Task { @MainActor in
            let autoFillEnabled = await credentialManager.isAutoFillEnabled()
            if case .autoFill = state, autoFillEnabled {
                state = .autoFillEnabled
            }
        }
    }

    private func finishOnboarding() {
        preferences.onboarded = true
        finished = true
    }
}

// MARK: - Public actions
extension OnboardingViewModel {
    func primaryAction() {
        switch state {
        case .autoFill:
            UIApplication.shared.openPasswordSettings()

        case .autoFillEnabled:
            if preferences.biometricAuthenticationEnabled {
                state = .biometricAuthenticationEnabled
            } else {
                state = .biometricAuthentication
            }

        case .biometricAuthentication:
            biometricAuthenticator.toggleEnabled(force: true)

        case .biometricAuthenticationEnabled:
            state = .aliases

        case .aliases:
            finishOnboarding()
        }
    }

    func secondaryAction() {
        switch state {
        case .autoFill, .autoFillEnabled:
            if preferences.biometricAuthenticationEnabled {
                state = .biometricAuthenticationEnabled
            } else {
                state = .biometricAuthentication
            }
        case .biometricAuthentication, .biometricAuthenticationEnabled:
            state = .aliases
        case .aliases:
            finishOnboarding()
        }
    }
}
