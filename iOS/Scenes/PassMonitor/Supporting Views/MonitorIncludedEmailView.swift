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
import Screens
import SwiftUI

struct MonitorIncludedEmailView: View {
    let address: any Breachable
    let action: () -> Void

    var body: some View {
        HStack {
            leadingView
            Spacer()
            trailingView
        }
        .buttonEmbeded(action: action)
    }
}

private extension MonitorIncludedEmailView {
    var leadingView: some View {
        VStack(alignment: .leading) {
            Text(address.email)
                .foregroundStyle(address.isBreached ?
                    PassColor.passwordInteractionNormMajor2 : PassColor.textNorm)
            if let lastBreachDate = address.lastBreachDate {
                Text("Latest breach on \(lastBreachDate)")
                    .font(.callout)
                    .foregroundStyle(PassColor.textNorm)
            } else {
                Text("No breaches detected")
                    .font(.callout)
                    .foregroundStyle(PassColor.cardInteractionNormMajor1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var trailingView: some View {
        if address.isBreached {
            CapsuleCounter(count: address.breachCounter,
                           foregroundStyle: SecureRowType.danger.iconColor,
                           background: SecureRowType.danger.background)
        }
        ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                              color: address.isBreached ?
                                  PassColor.passwordInteractionNormMajor2 : PassColor.textWeak,
                              width: 15)
    }
}

private extension Breachable {
    // swiftlint:disable:next todo
    // TODO: Should update Breachable protocol to not only rely on breach count but more towards flags
    var isBreached: Bool {
        breachCounter > 0
    }
}
