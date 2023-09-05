//
// NotLoggedInView.swift
// Proton Pass - Created on 27/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct NotLoggedInView: View {
    private let theme = resolve(\SharedToolingContainer.theme)
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                Text("Please log in in order to use Proton Pass AutoFill extension")
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(uiColor: PassColor.backgroundNorm))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 action: onCancel)
                }
            }
        }
        .navigationViewStyle(.stack)
        .theme(theme)
    }
}
