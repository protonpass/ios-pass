//
// EditDefaultBrowserView.swift
// Proton Pass - Created on 31/03/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import SwiftUI
import UIComponents

struct EditDefaultBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let supportedBrowsers: [Browser]
    let preferences: Preferences

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 22) {
                NotchView()
                    .padding(.top, 5)
                Text("Default browser")
                    .navigationTitleText()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            ScrollView {
                VStack {
                    VStack(spacing: 0) {
                        ForEach(supportedBrowsers, id: \.rawValue) { browser in
                            SelectableOptionRow(action: { preferences.browser = browser; dismiss() },
                                                height: .short,
                                                content: { Text(browser.description) },
                                                isSelected: browser == preferences.browser)

                            if browser != supportedBrowsers.last {
                                PassDivider()
                            }
                        }
                    }
                    .roundedEditableSection()

                    Text("This preference will fallback to Safari if the browser of choice is uninstalled.")
                        .sectionTitleText()
                }
                .padding([.top, .horizontal])
            }
        }
        .background(Color.passSecondaryBackground)
    }
}
