//
// MonitorIncludedEmailView.swift
// Proton Pass - Created on 24/04/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

struct MonitorIncludedEmailView: View {
    let address: ProtonAddress
    let action: () -> Void

    var body: some View {
        HStack {
            leadingView
            Spacer()
            trailingView
        }
        .contentShape(Rectangle())
        .buttonEmbeded(action)
    }
}

private extension MonitorIncludedEmailView {
    var leadingView: some View {
        VStack(alignment: .leading) {
            Text(address.email)
                .foregroundStyle(address.isBreached ?
                    PassColor.passwordInteractionNormMajor2.toColor : PassColor.textNorm.toColor)
            if let lastBreachDate = address.lastBreachDate {
                Text("Latest breach on \(lastBreachDate)")
                    .font(.callout)
                    .foregroundStyle(PassColor.textNorm.toColor)
            } else {
                Text("No breaches detected")
                    .font(.callout)
                    .foregroundStyle(PassColor.cardInteractionNormMajor1.toColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var trailingView: some View {
        if address.isBreached {
            BreachCounterView(count: address.breachCounter, type: .danger)
        }
        ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                              color: address.isBreached ?
                                  PassColor.passwordInteractionNormMajor2 : PassColor.textWeak,
                              width: 15)
    }
}
