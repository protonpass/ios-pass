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
        .animation(.default, value: viewModel.currentStep)
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

            if let ctaTitle = currentStep.ctaTitle {
                ctaButton(with: ctaTitle)
                    .padding(DesignConstant.onboardingPadding)
            }
        }
        .background(LinearGradient(stops:
            [
                Gradient.Stop(color: Color(red: 0.81, green: 0.51, blue: 0.53), location: 0.00),
                Gradient.Stop(color: Color(red: 0.29, green: 0.2, blue: 0.47), location: 0.59),
                Gradient.Stop(color: Color(red: 0.12, green: 0.12, blue: 0.19), location: 1.00)
            ],
            startPoint: UnitPoint(x: 0, y: 0),
            endPoint: UnitPoint(x: 0.66, y: 0.36)))
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
            descriptiveIllustration(illustration: PassIcon.onboardFaceID,
                                    illustrationMaxHeight: 215,
                                    title: "Protect your most sensitive data",
                                    // swiftlint:disable:next line_length
                                    description: "Set Proton Pass to unlock with your face or fingerprint so only you have access.")

        case .autofill:
            descriptiveIllustration(illustration: PassIcon.onboardAutoFill,
                                    illustrationMaxHeight: 204,
                                    title: "Enjoy the magic of AutoFill",
                                    // swiftlint:disable:next line_length
                                    description: "Automatically enter your passwords in Safari and other apps in a really fast and easy way.")

        case .createFirstLogin:
            Text(verbatim: "Create first login")
        }
    }

    func descriptiveIllustration(illustration: UIImage,
                                 illustrationMaxHeight: CGFloat,
                                 title: LocalizedStringKey,
                                 description: LocalizedStringKey) -> some View {
        VStack(alignment: .center, spacing: DesignConstant.sectionPadding) {
            Spacer()

            Image(uiImage: illustration)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: illustrationMaxHeight)
                .padding(.horizontal, 22)

            Spacer(minLength: 24)

            Text(title, bundle: .module)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(.horizontal, DesignConstant.onboardingPadding)

            Text(description, bundle: .module)
                .font(.title3)
                .foregroundStyle(PassColor.textWeak.toColor)
                .padding(.horizontal, DesignConstant.onboardingPadding)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
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

    func ctaButton(with title: String) -> some View {
        CapsuleTextButton(title: title,
                          titleColor: PassColor.textInvert,
                          backgroundColor: PassColor.interactionNormMajor2,
                          height: 52,
                          action: { Task { await viewModel.performCta() } })
    }
}

private extension OnboardV2Step {
    var ctaTitle: String? {
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

        case .createFirstLogin:
            nil
        }
    }
}
