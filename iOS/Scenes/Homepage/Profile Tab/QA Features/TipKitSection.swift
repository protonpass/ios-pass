//
// TipKitSection.swift
// Proton Pass - Created on 21/03/2024.
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

import Core
import DesignSystem
import SwiftUI
import TipKit

@available(iOS 17, *)
struct TipKitSection: View {
    @AppStorage(Constants.QA.resetTipsStateOnLaunch)
    private var resetTipsStateOnLaunch = false

    @AppStorage(Constants.QA.forceShowTips)
    private var forceShowTips = false

    var body: some View {
        Section(content: {
            Toggle(isOn: $resetTipsStateOnLaunch) {
                Text(verbatim: "Reset tips' state on launch")
                Text(verbatim: "Test tips' eligibilities.")
            }

            Toggle(isOn: $forceShowTips) {
                Text(verbatim: "Force show tips")
                Text(verbatim: "Show tips regardless of their state. Test how tips look like.")
            }

            tipDetail(title: "Force touch",
                      // swiftlint:disable:next line_length
                      description: "Performed >= 10 times eligible actions via item detail pages (pin/unpin/copy username...)")

            tipDetail(title: "Spotlight",
                      description: "Picked search result/history >= 10 times & Spotlight is not yet enabled.")
        }, header: {
            Text(verbatim: "Tips")
        })
    }

    func tipDetail(title: String, description: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(PassColor.textNorm)
            Text(description)
                .font(.caption)
                .foregroundStyle(PassColor.textWeak)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
