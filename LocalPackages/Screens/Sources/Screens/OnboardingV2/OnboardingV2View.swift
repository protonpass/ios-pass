//
// OnboardingV2View.swift
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

import DesignSystem
import Entities
import Macro
import SwiftUI

public struct OnboardingV2View: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: OnboardingV2ViewModel

    public init(isFreeUser: Bool,
                availableBiometricType: BiometricType?) {
        _viewModel = .init(wrappedValue: .init(isFreeUser: isFreeUser,
                                               availableBiometricType: availableBiometricType))
    }

    public var body: some View {
        VStack {
            skipButton
            ctaButton
        }
        .onChange(of: viewModel.finished) { _ in
            dismiss()
        }
    }
}

private extension OnboardingV2View {
    var skipButton: some View {
        Button(action: {
            if !viewModel.goNext() {
                dismiss()
            }
        }, label: {
            Text("Skip", bundle: .main)
                .foregroundStyle(.white)
        })
    }

    var ctaButton: some View {
        CapsuleTextButton(title: viewModel.currentStep.ctaTitle,
                          titleColor: PassColor.interactionNormMajor2,
                          backgroundColor: PassColor.interactionNormMinor1,
                          height: 52,
                          action: viewModel.performCta)
    }
}

private extension OnboardV2Step {
    var ctaTitle: String {
        switch self {
        case .payment:
            #localized("Get Pass Plus", bundle: .module)

        case let .biometric(type):
            switch type {
            case .faceID:
                #localized("Enable Face ID", bundle: .module)
            case .touchID:
                #localized("Enable Touch ID", bundle: .module)
            case .opticID:
                #localized("Enable Optic ID", bundle: .module)
            }

        case .autofill:
            #localized("Turn on AutoFill", bundle: .module)
        }
    }
}
