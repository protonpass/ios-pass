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
import Entities
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct MonitorProtonAddressesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MonitorProtonAddressesViewModel
    @EnvironmentObject private var router: PathRouter

    var body: some View {
        LazyVStack {
            if viewModel.access?.monitor.protonAddress == true {
                enabledView
            } else {
                disabledView
            }
            Spacer()
        }
        .id(UUID())
        .padding(.horizontal)
        .scrollViewEmbeded()
        .animation(.default, value: viewModel.access)
        .animation(.default, value: viewModel.allAddresses)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Proton addresses")
        .navigationBarBackButtonHidden()
    }
}

private extension MonitorProtonAddressesView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        if let access = viewModel.access {
            ToolbarItem(placement: .topBarTrailing) {
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

    func select(_ address: ProtonAddress) {
        guard viewModel.access?.monitor.protonAddress == true else { return }
        router.navigate(to: .breachDetail(.protonAddress(address)))
    }
}

private extension MonitorProtonAddressesView {
    @ViewBuilder
    var enabledView: some View {
        ForEach(viewModel.monitoredAddresses) { address in
            MonitorIncludedEmailView(address: address, action: { select(address) })
                .padding(.bottom)
        }

        if !viewModel.excludedAddresses.isEmpty {
            Section(content: {
                ForEach(viewModel.excludedAddresses) { address in
                    MonitorExcludedEmailView(address: address, action: { select(address) })
                        .padding(.bottom)
                }
            }, header: {
                Text("Excluded from monitoring")
                    .monitorSectionTitleText()
                    .padding(.top, DesignConstant.sectionPadding)
            })
        }
    }
}

private extension MonitorProtonAddressesView {
    @ViewBuilder
    var disabledView: some View {
        Text("Enable monitoring to get notified if your Proton addresses were leaked.")
            .foregroundStyle(PassColor.textNorm.toColor)
            .padding(.vertical)
        ForEach(viewModel.allAddresses) { address in
            MonitorExcludedEmailView(address: address)
                .padding(.bottom)
        }
    }
}
