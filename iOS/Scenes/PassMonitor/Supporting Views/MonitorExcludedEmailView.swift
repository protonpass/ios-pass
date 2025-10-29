//
// MonitorExcludedEmailView.swift
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

struct MonitorExcludedEmailView: View {
    let address: any Breachable
    var action: (() -> Void)?

    var body: some View {
        HStack {
            leadingView
            if action != nil {
                Spacer()
                ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                                      color: PassColor.textWeak,
                                      width: 15)
            }
        }
        .contentShape(.rect)
        .buttonEmbeded {
            action?()
        }
    }
}

private extension MonitorExcludedEmailView {
    var leadingView: some View {
        VStack(alignment: .leading) {
            Text(address.email)
                .foregroundStyle(PassColor.textNorm)
            if let lastBreachDate = address.lastBreachDate {
                Text("Latest breach on \(lastBreachDate)")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak)
            } else {
                Text("No breaches detected")
                    .font(.callout)
                    .foregroundStyle(PassColor.cardInteractionNormMajor1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
