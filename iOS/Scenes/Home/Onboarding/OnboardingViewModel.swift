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
import SwiftUI

final class OnboardingViewModel: ObservableObject {
    @Published private(set) var finished = false
    @Published private(set) var state = OnboardingViewState.autoFill

    private let credentialManager: CredentialManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    init(credentialManager: CredentialManagerProtocol) {
        self.credentialManager = credentialManager
        checkAutoFillStatus()
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkAutoFillStatus()
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
}

// MARK: - Public actions
extension OnboardingViewModel {
    func primaryAction() {
        switch state {
        case .autoFill:
            UIApplication.shared.openSettings()
        case .autoFillEnabled:
            break
        case .biometricAuthentication:
            break
        case .biometricAuthenticationEnabled:
            break
        case .aliases:
            break
        }
    }

    func secondaryAction() {
        switch state {
        case .autoFill, .autoFillEnabled:
            state = .biometricAuthentication
        case .biometricAuthentication, .biometricAuthenticationEnabled:
            state = .aliases
        case .aliases:
            finished = true
        }
    }
}
