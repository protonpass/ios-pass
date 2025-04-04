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
import Entities
import Macro
import SwiftUI

private enum PaidFeature: CaseIterable {
    case unlimitedAliases
    case darkWebMonitoring
    case secureLinks
    case protonSentinel
}

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
    let plans: [PlanUiModel]
    @Binding var selectedPlan: PlanUiModel?

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
                //            paidFeatures
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

    var paidFeatures: some View {
        TabView {
            ForEach(PaidFeature.allCases, id: \.self) { feature in
                VStack(alignment: .center) {
                    Image(uiImage: feature.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                    Text(feature.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .padding(.horizontal, DesignConstant.onboardingPadding)
                    Text(feature.description)
                        .font(.headline)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .padding(.horizontal, DesignConstant.onboardingPadding)
                }
                .multilineTextAlignment(.center)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .never))
    }

    func view(for plans: [PlanUiModel]) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Select your plan")
                .foregroundStyle(PassColor.textWeak.toColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            ForEach(plans) { plan in
                PlanCell(plan: plan,
                         selected: selectedPlan == plan,
                         onSelect: { selectedPlan = plan })
            }

            if let selectedPlan {
                let price = String(format: "%.2f", selectedPlan.price)
                let fullPrice = "\(selectedPlan.currency) \(price)\(selectedPlan.recurrence.cycleUnit)"
                Text("Subscription auto renews at \(fullPrice)")
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
    let plan: PlanUiModel
    let selected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack {
            Text(plan.recurrence.title)
                .font(.headline)
                .foregroundStyle(PassColor.textNorm.toColor)

            if plan.recurrence == .yearly {
                Text(verbatim: "-35%")
                    .font(.caption)
                    .foregroundStyle(PassColor.textInvert.toColor)
                    .padding(4)
                    .background(PassColor.noteInteractionNormMajor1.toColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Spacer()

            VStack {
                Text(verbatim: "\(plan.currency) \(String(format: "%.2f", plan.price)) ")
                    .font(.headline)
                    .fontWeight(.bold)
                    .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                    Text(plan.recurrence.cycleUnit)
                    .font(.callout)
                    .adaptiveForegroundStyle(PassColor.textWeak.toColor)

                if plan.recurrence == .yearly {
                    let monthlyPrice = String(format: "%.2f", plan.price / 12)
                    Text(verbatim: "\(plan.currency) \(monthlyPrice)\(PlanUiModel.Recurrence.monthly.cycleUnit)")
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak.toColor)
                }
            }
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
        .onTapGesture(perform: onSelect)
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

// swiftlint:disable:next todo
// TODO: [OnboardingV2] Localize & update these copies
private extension PaidFeature {
    var icon: UIImage {
        PassIcon.stamp
    }

    var title: String {
        switch self {
        case .unlimitedAliases:
            "Unlimited hide-my-email aliases"
        case .darkWebMonitoring:
            "Dark web monitoring"
        case .secureLinks:
            "Secure links"
        case .protonSentinel:
            "Proton Sentinel"
        }
    }

    var description: String {
        switch self {
        case .unlimitedAliases:
            "Create aliases to keep your actual email address protected."
        case .darkWebMonitoring:
            "Dark web monitoring description"
        case .secureLinks:
            "Secure links description"
        case .protonSentinel:
            "Proton Sentinel description"
        }
    }
}

private extension PlanUiModel.Recurrence {
    var title: LocalizedStringKey {
        switch self {
        case .monthly: "1 month"
        case .yearly: "1 year"
        }
    }

    var cycleUnit: String {
        switch self {
        case .monthly: #localized("/month", bundle: .module)
        case .yearly: #localized("/year", bundle: .module)
        }
    }
}
