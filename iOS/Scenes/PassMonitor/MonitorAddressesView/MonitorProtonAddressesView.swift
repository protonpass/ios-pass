//
// MonitorProtonAddressesView.swift
// Proton Pass - Created on 23/04/2024.
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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct MonitorProtonAddressesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MonitorProtonAddressesViewModel
    private let router = resolve(\RouterContainer.darkWebRouter)

    var body: some View {
        LazyVStack {
            if viewModel.access?.monitor.protonAddress == true {
                enabledView
            } else {
                disabledView
            }
        }
        .scrollViewEmbeded()
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Proton addresses")
        .navigationBarBackButtonHidden()
        .toolbar { toolbarContent }
    }
}

private extension MonitorProtonAddressesView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        if let access = viewModel.access {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu(content: {
                    ToggleMonitorButton(monitored: access.monitor.protonAddress,
                                        action: { viewModel.toggleMonitor() })
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Options")
                })
            }
        }
    }
}

private extension MonitorProtonAddressesView {
    @ViewBuilder
    var enabledView: some View {
        Text(verbatim: "enabled")
    }
}

private extension MonitorProtonAddressesView {
    @ViewBuilder
    var disabledView: some View {
        Text("Enable monitoring to get notified if your Proton addresses were leaked.")
            .foregroundStyle(PassColor.textNorm.toColor)
    }
}
