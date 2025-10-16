//
// OnboardingView.swift
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
import ProtonCoreUIFoundations
import SwiftUI

public struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: OnboardingViewModel
    @State private var saveable = false
    @State private var topBar: TopBar = .notNowButton

    enum TopBar {
        case none
        case notNowButton
        case createFirstLogin(KnownService,
                              onClose: () -> Void,
                              onSave: () -> Void)
    }

    public init(handler: OnboardingHandling?, mode: OnboardingDisplayMode) {
        _viewModel = .init(wrappedValue: .init(handler: handler, mode: mode))
    }

    public var body: some View {
        ZStack {
            switch viewModel.currentStep {
            case .fetching:
                ProgressView()

            case let .fetched(step):
                mainContainer(for: step)

            case let .error(error):
                VStack(alignment: .center) {
                    RetryableErrorView(mode: .defaultHorizontal,
                                       error: error,
                                       onRetry: { Task { await viewModel.setUp() } })
                    Button(action: dismiss.callAsFunction) {
                        Text("Cancel", bundle: .module)
                            .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .showSpinner(viewModel.isPurchasing)
        .task { await viewModel.setUp() }
    }
}

private extension OnboardingView {
    func mainContainer(for step: OnboardStep) -> some View {
        VStack(spacing: 0) {
            topBarView
                .animation(.default, value: viewModel.isSaving)
            content(for: step)
            ctaButton(for: step)
                .animation(.default, value: viewModel.currentStep)
            secondaryCtaButton(for: step)
                .animation(.default, value: viewModel.currentStep)
        }
        .background(background(for: step))
        .onChange(of: viewModel.isSaving) { newValue in
            if !newValue {
                topBar = .none
            }
        }
        .onChange(of: viewModel.finished) { _ in
            dismiss()
        }
    }

    func background(for step: OnboardStep) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(stops:
                [
                    Gradient.Stop(color: Color(red: 0.81, green: 0.51, blue: 0.53), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.29, green: 0.2, blue: 0.47), location: 0.59),
                    Gradient.Stop(color: Color(red: 0.12, green: 0.12, blue: 0.19), location: 1.00)
                ],
                startPoint: UnitPoint(x: 0, y: 0),
                endPoint: UnitPoint(x: 0.66, y: 0.36))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            if case .payment = step {
                GeometryReader { proxy in
                    let imageWidth = proxy.size.width
                    Image(uiImage: PassIcon.passIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageWidth)
                        .offset(x: -imageWidth * 0.3, y: -imageWidth * 0.65)
                }
            }
        }
    }

    var topBarView: some View {
        HStack {
            switch topBar {
            case .none:
                EmptyView()

            case .notNowButton:
                Spacer()
                notNowButton

            case let .createFirstLogin(service, onClose, onSave):
                ZStack {
                    HStack {
                        CircleButton(icon: IconProvider.cross,
                                     iconColor: PassColor.interactionNormMajor2,
                                     backgroundColor: .black.withAlphaComponent(0.15),
                                     accessibilityLabel: "Close",
                                     action: onClose)

                        Spacer()

                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            DisablableCapsuleTextButton(title: #localized("Save", bundle: .module),
                                                        titleColor: PassColor.textInvert,
                                                        disableTitleColor: PassColor.textHint,
                                                        backgroundColor: PassColor.interactionNormMajor1,
                                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                                        disabled: !saveable,
                                                        maxWidth: nil,
                                                        action: onSave)
                                .accessibilityLabel("Save")
                        }
                    }

                    KnownServiceThumbnail(service: service)
                }
            }
        }
        .padding(UIDevice.current.isIpad ? .all : .horizontal, DesignConstant.onboardingPadding)
    }

    @ViewBuilder
    func content(for step: OnboardStep) -> some View {
        switch step {
        case let .payment(plans):
            OnboardingPaymentStep(plans: plans,
                                  selectedPlan: $viewModel.selectedPlan,
                                  onPurchase: viewModel.purchaseSelectedPlan)

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

        case .aliasExplanation:
            descriptiveIllustration(illustration: PassIcon.onboardAliasExplanation,
                                    illustrationMaxHeight: 300,
                                    title: "Control what lands in your inbox",
                                    // swiftlint:disable:next line_length
                                    description: "Stop sharing your real email address. Instead hide it with email aliases-a Proton Pass exclusive.")
                .onAppear {
                    topBar = .none
                }

        case let .createFirstLogin(shareId, services):
            OnboardingCreateFirstLoginStep(saveable: $saveable,
                                           topBar: $topBar,
                                           shareId: shareId,
                                           services: services,
                                           onCreate: viewModel.createFirstLogin(payload:))

        case let .firstLoginCreated(payload):
            OnboardingFirstLoginCreatedStep(payload: payload)
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

    var notNowButton: some View {
        Button(action: {
            Task {
                if await !viewModel.goNext(isManual: true) {
                    dismiss()
                }
            }
        }, label: {
            Text("Not now", bundle: .module)
                .font(.callout)
                .foregroundStyle(.white)
        })
    }

    @ViewBuilder
    func ctaButton(for step: OnboardStep) -> some View {
        if let ctaTitle = step.ctaTitle {
            CapsuleTextButton(title: ctaTitle,
                              titleColor: PassColor.textInvert,
                              font: .body,
                              backgroundColor: PassColor.interactionNormMajor2,
                              height: 52,
                              action: { Task { await viewModel.performCta() } })
                .padding(.horizontal, DesignConstant.onboardingPadding)
                .padding(.vertical, DesignConstant.sectionPadding)
        }
    }

    @ViewBuilder
    func secondaryCtaButton(for step: OnboardStep) -> some View {
        if let secondaryCtaTitle = step.secondaryCtaTitle {
            CapsuleTextBorderedButton(title: secondaryCtaTitle,
                                      titleColor: .white,
                                      font: .body,
                                      borderColor: .white.opacity(0.3),
                                      height: 52,
                                      action: viewModel.performSecondaryCta)
                .padding(.horizontal, DesignConstant.onboardingPadding)
                .padding(.bottom, DesignConstant.sectionPadding)
        }
    }
}

private extension OnboardStep {
    var ctaTitle: String? {
        switch self {
        case .payment:
            nil

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

        case .aliasExplanation:
            #localized("Start using Proton Pass", bundle: .module)

        case .createFirstLogin:
            nil

        case .firstLoginCreated:
            #localized("Get Started", bundle: .module)
        }
    }

    var secondaryCtaTitle: String? {
        if case .aliasExplanation = self {
            #localized("Learn how to use Proton Pass", bundle: .module)
        } else {
            nil
        }
    }
}
