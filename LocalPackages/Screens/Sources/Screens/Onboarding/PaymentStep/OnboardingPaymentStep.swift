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
import Macro
import ProtonCorePaymentsV2
import SwiftUI

struct OnboardingPaymentStep: View {
    @State private var selection: Selection = .plus
    let plans: PassPlans
    @Binding var selectedPlan: PlanUiModel?
    let onPurchase: () -> Void

    private enum Selection {
        case plus, unlimited

        var ctaTitle: String {
            switch self {
            case .plus:
                #localized("Get Pass Plus", bundle: .module)
            case .unlimited:
                #localized("Get Proton Unlimited", bundle: .module)
            }
        }
    }

    var body: some View {
        VStack {
            Spacer()
                .frame(maxHeight: 52)

            Text("Unlock premium features.", bundle: .module)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignConstant.onboardingPadding)

            planSelector
                .padding(.horizontal, DesignConstant.onboardingPadding)
                .animation(.default, value: selection)

            ScrollView(showsIndicators: false) {
                switch selection {
                case .plus:
                    OnboardingPassPlusView()
                case .unlimited:
                    OnboardingProtonUnlimitedView()
                }
            }
            .padding(.horizontal, DesignConstant.onboardingPadding)

            ctaButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            selectedPlan = plans.plus
        }
    }
}

private extension OnboardingPaymentStep {
    var planSelector: some View {
        HStack {
            planDetail(name: "Plus",
                       plan: plans.plus,
                       selected: selection == .plus,
                       onSelect: {
                           selection = .plus
                           selectedPlan = plans.plus
                       })
            planDetail(name: "Unlimited",
                       plan: plans.unlimited,
                       selected: selection == .unlimited,
                       onSelect: {
                           selection = .unlimited
                           selectedPlan = plans.unlimited
                       })
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(GeometryReader { proxy in
            HStack {
                if selection == .unlimited {
                    Spacer()
                }

                Color.white
                    .clipShape(.capsule)
                    .frame(maxWidth: proxy.size.width / 2)

                if selection == .plus {
                    Spacer()
                }
            }
        })
        .padding(4)
        .background(Color.black.opacity(0.3).clipShape(.capsule))
    }

    func planDetail(name: String,
                    plan: PlanUiModel,
                    selected: Bool,
                    onSelect: @escaping () -> Void) -> some View {
        VStack(alignment: .center) {
            Text(verbatim: name)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(verbatim: plan.displayMonthlyPrice)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .foregroundStyle(selected ? PassColor.textInvert.toColor : .white)
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
    }

    var ctaButton: some View {
        VStack(alignment: .center, spacing: 0) {
            CapsuleTextButton(title: selection.ctaTitle,
                              titleColor: PassColor.textInvert,
                              font: .body,
                              fontWeight: .medium,
                              backgroundColor: .white,
                              height: 52,
                              action: onPurchase)
                .padding(DesignConstant.onboardingPadding)

            if let selectedPlan {
                Text("Auto renews at \(selectedPlan.displayYearlyPrice) every year",
                     bundle: .module)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding([.bottom, .horizontal], DesignConstant.onboardingPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: -4)
        .overlay(alignment: .top) {
            Rectangle()
                .inset(by: 0.5)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(height: 1)
        }
    }
}
