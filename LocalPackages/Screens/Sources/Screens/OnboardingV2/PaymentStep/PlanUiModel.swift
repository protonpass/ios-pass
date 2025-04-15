//
// PlanUiModel.swift
// Proton Pass - Created on 10/04/2025.
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

import Macro
import ProtonCorePaymentsV2
import StoreKit

struct PlanUiModel: Equatable {
    let plan: ComposedPlan
    let displayMonthlyPrice: String
    let displayYearlyPrice: String

    init?(plan: ComposedPlan) {
        self.plan = plan
        guard let product = plan.product as? Product else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.locale = product.priceFormatStyle.locale
        formatter.numberStyle = .currency

        let monthlyPrice = (product.price / 12) as NSNumber
        guard let monthlyPrice = formatter.string(from: monthlyPrice),
              let yearlyPrice = formatter.string(from: product.price as NSNumber) else {
            return nil
        }
        displayMonthlyPrice = #localized("%@/month", bundle: .module, monthlyPrice)
        displayYearlyPrice = yearlyPrice
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.plan.plan.id == rhs.plan.plan.id
    }
}
