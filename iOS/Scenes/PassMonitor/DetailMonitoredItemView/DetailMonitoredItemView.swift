//
//
// DetailMonitoredItemView.swift
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
//

import DesignSystem
import Entities
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct DetailMonitoredItemView: View {
    @StateObject var viewModel: DetailMonitoredItemViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: PathRouter
    @State private var showResolveExplanation = false

    var body: some View {
        ZStack {
            PassColor.backgroundNorm
                .ignoresSafeArea()
            switch viewModel.state {
            case .fetching:
                ProgressView()
            case let .fetched(uiModel):
                content(uiModel)
            case let .error(error):
                RetryableErrorView(error: error,
                                   onRetry: { Task { await viewModel.fetchData() } })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PassColor.backgroundNorm, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task {
            await viewModel.fetchData()
        }
        .onChange(of: viewModel.shouldDismiss) { _ in
            dismiss()
        }
        .alert("Mark as resolved",
               isPresented: $showResolveExplanation,
               actions: {
                   Button(action: { viewModel.markAsResolved() },
                          label: { Text("Confirm") })
                   Button(role: .cancel,
                          label: { Text("Cancel") })
               },
               message: {
                   // swiftlint:disable:next line_length
                   Text("All current breaches will be marked as resolved. In case of future data breaches, you'll be notified.")
               })
    }
}

private extension DetailMonitoredItemView {
    func content(_ uiModel: DetailMonitoredItemUiModel) -> some View {
        VStack {
            header(email: uiModel.email,
                   breachCount: uiModel.unresolvedBreaches.count,
                   isFullyResolved: uiModel.isFullyResolved)
            LazyVStack {
                if !uiModel.unresolvedBreaches.isEmpty {
                    breachesSection(breaches: uiModel.unresolvedBreaches, resolved: false)
                }
                if !uiModel.resolvedBreaches.isEmpty {
                    breachesSection(breaches: uiModel.resolvedBreaches, resolved: true)
                }
                if !uiModel.linkedItems.isEmpty {
                    linkedItemSection(linkedItems: uiModel.linkedItems)
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollViewEmbeded(maxWidth: .infinity)
    }
}

private extension DetailMonitoredItemView {
    func header(email: String, breachCount: Int, isFullyResolved: Bool) -> some View {
        VStack(alignment: .center, spacing: DesignConstant.sectionPadding) {
            let isNotBreached = breachCount == 0
            Text(verbatim: "\(breachCount)")
                .font(.title)
                .foregroundStyle(isNotBreached ? PassColor.textNorm : PassColor
                    .passwordInteractionNormMajor2)
                .frame(height: 41)
                .padding(16)
                .background(isNotBreached ? PassColor.backgroundMedium : PassColor
                    .passwordInteractionNormMinor2)
                .clipShape(Circle())
            VStack(alignment: .center, spacing: 5) {
                Text(isNotBreached ? "No breaches detected for" : "Breach detected for")
                    .fontWeight(.medium)
                    .foregroundStyle(isNotBreached ? PassColor.cardInteractionNormMajor1 : PassColor
                        .passwordInteractionNormMajor2)
                Text(email)
                    .foregroundStyle(PassColor.textNorm)
                    .multilineTextAlignment(.center)
            }

            if !viewModel.isMonitored {
                Text("Excluded from monitoring")
                    .font(.caption2)
                    .foregroundStyle(PassColor.textNorm)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(PassColor.textDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if !isFullyResolved {
                CapsuleTextButton(title: #localized("Mark as resolved"),
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: PassColor.interactionNormMinor1,
                                  height: 48,
                                  action: { showResolveExplanation.toggle() })
            }
        }
    }
}

private extension DetailMonitoredItemView {
    func breachesSection(breaches: [Breach], resolved: Bool) -> some View {
        Section {
            ForEach(breaches) { breach in
                breachRow(breach: breach, resolved: resolved)
            }
        } header: {
            createSectionHeader(title: resolved ? "Resolved breaches" : "Breaches")
        }
    }
}

private extension DetailMonitoredItemView {
    func linkedItemSection(linkedItems: [ItemUiModel]) -> some View {
        Section {
            ForEach(linkedItems) { item in
                itemRow(for: item)
            }
        } header: {
            createSectionHeader(title: "Used in")
        }
    }
}

// MARK: - Utils

private extension DetailMonitoredItemView {
    func breachRow(breach: Breach, resolved: Bool) -> some View {
        Button { router.present(sheet: .breachDetail(breach)) } label: {
            HStack(spacing: DesignConstant.sectionPadding) {
                (resolved ? PassIcon.breachShieldResolved : PassIcon.breachShieldUnresolved)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 43)

                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text(breach.name)
                        .foregroundStyle(PassColor.textNorm)

                    Text(breach.breachDate)
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak)
                }
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .contentShape(.rect)
            }
        }
        .buttonStyle(.plain)
    }

    func itemRow(for uiModel: ItemUiModel) -> some View {
        Button { viewModel.goToDetailPage(item: uiModel) } label: {
            GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: uiModel.thumbnailData()) },
                           title: uiModel.title,
                           description: uiModel.description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func createSectionHeader(title: LocalizedStringKey) -> some View {
        Text(title)
            .monitorSectionTitleText()
            .padding(.top, DesignConstant.sectionPadding)
    }
}

// MARK: - Toolbar setup

private extension DetailMonitoredItemView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        if viewModel.state.isFetched {
            ToolbarItem(placement: .topBarTrailing) {
                Menu(content: {
                    if viewModel.isCustomEmail {
                        Button { viewModel.removeCustomMailFromMonitor() } label: {
                            Label(title: { Text("Remove") },
                                  icon: { IconProvider.trash })
                        }
                    } else {
                        ToggleMonitorButton(monitored: viewModel.isMonitored,
                                            action: { viewModel.toggleMonitoring() })
                    }
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Breach detail action menu")
                })
            }
        }
    }
}
