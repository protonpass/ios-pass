//
// MonitorAliasesView.swift
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

struct MonitorAliasesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MonitorAliasesViewModel
    @EnvironmentObject private var router: PathRouter

    var body: some View {
        LazyVStack {
            if viewModel.infos.isEmpty {
                Spacer()
                Image(uiImage: PassIcon.securityEmptyState)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 195)
            } else {
                if viewModel.access?.monitor.aliases == true {
                    enabledView
                } else {
                    disabledView
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .if(!viewModel.infos.isEmpty) { view in
            view.scrollViewEmbeded()
        }
        .animation(.default, value: viewModel.access)
        .animation(.default, value: viewModel.dismissedCustomDomainExplanation)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Hide-my-email aliases")
        .navigationBarBackButtonHidden()
    }
}

private extension MonitorAliasesView {
    @ViewBuilder
    var enabledView: some View {
        if !viewModel.dismissedCustomDomainExplanation {
            customDomainExplanation
                .padding(.vertical)
        }

        ForEach(viewModel.breachedAliases) { info in
            MonitorIncludedEmailView(address: info, action: { select(info) })
                .padding(.bottom)
        }

        if !viewModel.notBreachedAliases.isEmpty {
            Section(content: {
                ForEach(viewModel.notBreachedAliases.prefix(DesignConstant.previewBreachItemCount)) { info in
                    MonitorIncludedEmailView(address: info,
                                             action: { router.navigate(to: .breachDetail(.alias(info))) })
                        .padding(.bottom)
                }
            }, header: {
                HStack {
                    Text("Monitored")
                        .navigationTitleText()
                    Spacer()
                    if viewModel.notBreachedAliases.count > DesignConstant.previewBreachItemCount {
                        seeAllText(count: viewModel.notBreachedAliases.count)
                            .buttonEmbeded { seeAll(viewModel.notBreachedAliases, monitored: true) }
                    }
                }
                .padding(.top, DesignConstant.sectionPadding)
            })
        }

        if !viewModel.notMonitoredAliases.isEmpty {
            Section(content: {
                ForEach(viewModel.notMonitoredAliases.prefix(DesignConstant.previewBreachItemCount)) { info in
                    MonitorExcludedEmailView(address: info,
                                             action: { router.navigate(to: .breachDetail(.alias(info))) })
                        .padding(.bottom)
                }
            }, header: {
                HStack {
                    Text("Excluded from monitoring")
                        .navigationTitleText()
                    Spacer()
                    if viewModel.notMonitoredAliases.count > DesignConstant.previewBreachItemCount {
                        seeAllText(count: viewModel.notMonitoredAliases.count)
                            .buttonEmbeded { seeAll(viewModel.notMonitoredAliases, monitored: false) }
                    }
                }
                .padding(.top, DesignConstant.sectionPadding)
            })
        }
    }

    @ViewBuilder
    var disabledView: some View {
        Text("Enable monitoring to get notified if your aliases were leaked.")
            .foregroundStyle(PassColor.textNorm.toColor)
            .padding(.vertical)
        ForEach(viewModel.infos) { info in
            MonitorExcludedEmailView(address: info)
                .padding(.bottom)
        }
    }

    func seeAllText(count: Int) -> some View {
        Text("See all")
            .font(.callout)
            .adaptiveForegroundStyle(PassColor.interactionNormMajor2.toColor) +
            Text(verbatim: " (\(count))")
            .font(.callout)
            .adaptiveForegroundStyle(PassColor.interactionNormMajor2.toColor)
    }

    func select(_ info: AliasMonitorInfo) {
        guard viewModel.access?.monitor.aliases == true else { return }
        router.navigate(to: .breachDetail(.alias(info)))
    }

    func seeAll(_ infos: [AliasMonitorInfo], monitored: Bool) {
        router.navigate(to: .monitoredAliases(infos, monitored: monitored))
    }
}

private extension MonitorAliasesView {
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
                    ToggleMonitorButton(monitored: access.monitor.aliases,
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

private extension MonitorAliasesView {
    var customDomainExplanation: some View {
        HStack {
            Text("Aliases with custom domains are not monitored, please add them as a custom email for monitoring.")
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)
            VStack {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .buttonEmbeded { viewModel.dismissCustomDomainExplanation() }
                Spacer()
            }
        }
        .padding()
        .roundedEditableSection()
    }
}
