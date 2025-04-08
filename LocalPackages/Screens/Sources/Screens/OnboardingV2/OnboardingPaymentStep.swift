//
// OnboardingPaymentStep.swift
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
import ProtonCorePaymentsV2
import SwiftUI

private enum PassFeature: CaseIterable {
    case unlimitedLoginsNotesDevices
    case unlimitedAliases
    case twoFaAuthenticator
    case vaultSharing
    case secureLinks
    case unlimitedCreditCards
    case darkWebMonitoring
    case fileAttachments
    case advancedAliasManagement
}

private let kAvailabilityColumnWidth: CGFloat = 66

struct OnboardingPaymentStep: View {
    let plans: [ComposedPlan]
    @Binding var selectedPlan: ComposedPlan?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Spacer()
                        Color(red: 0.19, green: 0.18, blue: 0.27)
                            .frame(width: kAvailabilityColumnWidth)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    featureTable
                }
                view(for: plans)
            }
        }
        .padding(.horizontal, DesignConstant.onboardingPadding)
    }
}

private extension OnboardingPaymentStep {
    var featureTable: some View {
        LazyVGrid(columns:
            [
                .init(.flexible()),
                .init(.fixed(kAvailabilityColumnWidth)),
                .init(.fixed(kAvailabilityColumnWidth))
            ],
            spacing: DesignConstant.sectionPadding) {
                Text(verbatim: "")

                // swiftlint:disable:next todo
                // TODO: [OnboardingV2] Localize this
                Text(verbatim: "FREE")
                    .fontWeight(.bold)

                Image(uiImage: PassIcon.passSubscriptionBadge)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 42)

                ForEach(PassFeature.allCases, id: \.self) { feature in
                    Text(feature.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if feature.isFree {
                        checkmark
                    } else {
                        Image(systemName: "minus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16)
                    }
                    checkmark
                }
            }
            .foregroundStyle(PassColor.textNorm.toColor)
            .padding(.vertical)
    }

    var checkmark: some View {
        Image(systemName: "checkmark")
            .resizable()
            .scaledToFit()
            .frame(width: 16)
    }

    func view(for plans: [ComposedPlan]) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Select your plan")
                .foregroundStyle(PassColor.textWeak.toColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            ForEach(plans, id: \.product.id) { plan in
                PlanCell(plan: plan, selectedPlan: $selectedPlan)
            }

            if let selectedPlan {
                Text("Subscription auto renews at \(selectedPlan.product.displayPrice)")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .animationsDisabled()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, DesignConstant.onboardingPadding)
        .animation(.default, value: selectedPlan)
    }
}

private struct PlanCell: View {
    let plan: ComposedPlan
    @Binding var selectedPlan: ComposedPlan?

    var body: some View {
        let selected = plan.product.id == selectedPlan?.product.id
        HStack {
            Text(plan.product.displayName)
                .font(.headline)
                .foregroundStyle(PassColor.textNorm.toColor)

            Spacer()

            Text(verbatim: plan.product.displayPrice)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
        }
        .padding()
        .frame(height: 64)
        .background((selected ? PassColor.backgroundMedium : PassColor.backgroundWeak).toColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder((selected ? PassColor.textNorm : PassColor.borderWeak).toColor,
                              lineWidth: selected ? 2 : 1)
        }
        .contentShape(.rect)
        .onTapGesture {
            selectedPlan = plan
        }
    }
}

private extension PassFeature {
    var isFree: Bool {
        if case .unlimitedLoginsNotesDevices = self {
            true
        } else {
            false
        }
    }

    // swiftlint:disable:next todo
    // TODO: [OnboardingV2] Localize these copies
    var title: String {
        switch self {
        case .unlimitedLoginsNotesDevices:
            "Unlimited logins, notes, and devices"
        case .unlimitedAliases:
            "Unlimited hide-my-email aliases"
        case .twoFaAuthenticator:
            "2FA authenticator"
        case .vaultSharing:
            "Secure vault sharing"
        case .secureLinks:
            "Secure link sharing"
        case .unlimitedCreditCards:
            "Unlimited credit cards"
        case .darkWebMonitoring:
            "Dark Web Monitoring"
        case .fileAttachments:
            "File attachments"
        case .advancedAliasManagement:
            "Advanced alias management"
        }
    }
}
