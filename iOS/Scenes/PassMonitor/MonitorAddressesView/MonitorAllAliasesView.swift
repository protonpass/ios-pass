//
// MonitorAllAliasesView.swift
// Proton Pass - Created on 25/04/2024.
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
import Factory
import ProtonCoreUIFoundations
import SwiftUI

@MainActor
struct MonitorAllAliasesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: PathRouter
    let infos: [AliasMonitorInfo]
    let monitored: Bool

    var body: some View {
        LazyVStack {
            ForEach(infos) { info in
                if monitored {
                    MonitorIncludedEmailView(address: info, action: { select(info) })
                        .padding(.bottom)
                } else {
                    MonitorExcludedEmailView(address: info, action: { select(info) })
                        .padding(.bottom)
                }
            }
        }
        .padding(.horizontal)
        .scrollViewEmbeded()
        .background(PassColor.backgroundNorm.toColor)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleButton(icon: IconProvider.chevronLeft,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(monitored ? "Monitored" : "Excluded from monitoring")
        .navigationBarBackButtonHidden()
    }

    func select(_ info: AliasMonitorInfo) {
        router.navigate(to: .breachDetail(.alias(info)))
    }
}
