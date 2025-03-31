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
                datasource: OnboardingV2Datasource?,
                delegate: OnboardingV2Delegate?) {
        _viewModel = .init(wrappedValue: .init(isFreeUser: isFreeUser,
                                               datasource: datasource,
                                               delegate: delegate))
    }

    public var body: some View {
        ZStack {
            switch viewModel.currentStep {
            case .fetching:
                ProgressView()

            case let .fetched(step):
                mainContainer(currentStep: step)

            case let .error(error):
                VStack(alignment: .center) {
                    RetryableErrorView(mode: .defaultHorizontal,
                                       error: error,
                                       onRetry: { Task { await viewModel.setUp() } })
                    skipButton
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .task { await viewModel.setUp() }
    }
}

private extension OnboardingV2View {
    func mainContainer(currentStep: OnboardV2Step) -> some View {
        VStack {
            HStack {
                Spacer()
                skipButton
                    .padding([.top, .trailing], DesignConstant.onboardingPadding)
            }
            content(for: currentStep)
            ctaButton(for: currentStep)
                .padding(.horizontal, DesignConstant.onboardingPadding)
        }
        .onChange(of: viewModel.finished) { _ in
            dismiss()
        }
    }

    @ViewBuilder
    func content(for step: OnboardV2Step) -> some View {
        switch step {
        case let .payment(plans):
            OnboardingPaymentStep(plans: plans,
                                  selectedPlan: $viewModel.selectedPlan)

        case .biometric:
            Text(verbatim: "Biometric")

        case .autofill:
            Text(verbatim: "AutoFill")
        }
    }

    var skipButton: some View {
        Button(action: {
            Task {
                if await !viewModel.goNext() {
                    dismiss()
                }
            }
        }, label: {
            Text("Skip", bundle: .main)
                .foregroundStyle(.white)
        })
    }

    func ctaButton(for step: OnboardV2Step) -> some View {
        CapsuleTextButton(title: step.ctaTitle,
                          titleColor: PassColor.interactionNormMajor2,
                          backgroundColor: PassColor.interactionNormMinor1,
                          height: 52,
                          action: { Task { await viewModel.performCta() } })
    }
}

private extension OnboardV2Step {
    var ctaTitle: String {
        switch self {
        case .payment:
            #localized("Get Pass Plus", bundle: .module)

        case let .biometric(type):
            switch type {
            case .none:
                #localized("None", bundle: .module)
            case .faceID:
                #localized("Enable Face ID", bundle: .module)
            case .touchID:
                #localized("Enable Touch ID", bundle: .module)
            case .opticID:
                #localized("Enable Optic ID", bundle: .module)
            @unknown default:
                #localized("None", bundle: .module)
            }

        case .autofill:
            #localized("Turn on AutoFill", bundle: .module)
        }
    }
}
