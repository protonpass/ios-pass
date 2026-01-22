//
// UpsellSection.swift
// Proton Pass - Created on 20/01/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Core
import DesignSystem
import SwiftUI

struct UpsellSection: View {
    @AppStorage(Constants.QA.hidePassPlusPlan, store: kSharedUserDefaults)
    private var hidePassPlusPlan = false

    @AppStorage(Constants.QA.hideProtonUnlimitedPlan, store: kSharedUserDefaults)
    private var hideProtonUnlimitedPlan = false

    var body: some View {
        Section(content: {
            Toggle(isOn: $hidePassPlusPlan) {
                Text(verbatim: "Hide Pass Plus plan")
                    .foregroundStyle(PassColor.textNorm)
            }

            Toggle(isOn: $hideProtonUnlimitedPlan) {
                Text(verbatim: "Hide Proton Unlimited plan")
                    .foregroundStyle(PassColor.textNorm)
            }
        }, header: {
            Text(verbatim: "Upsell")
        })
    }
}
