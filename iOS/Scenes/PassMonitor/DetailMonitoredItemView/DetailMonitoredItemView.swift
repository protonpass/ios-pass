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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct DetailMonitoredItemView: View {
    @StateObject var viewModel: DetailMonitoredItemViewModel
    @Environment(\.dismiss) private var dismiss
    var router = resolve(\RouterContainer.darkWebRouter)

    var body: some View {
        mainContainer
    }
}

private extension DetailMonitoredItemView {
    var mainContainer: some View {
        VStack {
            headerInfo
            breachList
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension DetailMonitoredItemView {
    var headerInfo: some View {
        VStack(alignment: .center, spacing: DesignConstant.sectionPadding) {
            if let numberOfBreaches = viewModel.numberOfBreaches, let email = viewModel.email {
                Text(verbatim: "\(numberOfBreaches)")
                    .font(.title)
                    .foregroundStyle((viewModel.numberOfBreaches == 0 ? PassColor.textNorm : PassColor
                            .passwordInteractionNormMajor2).toColor)
                    .frame(height: 41)
                    .padding(16)
                    .background((numberOfBreaches == 0 ? PassColor.backgroundMedium : PassColor
                            .passwordInteractionNormMinor2).toColor)
                    .clipShape(Circle())
                VStack(alignment: .center, spacing: 5) {
                    Text("\(numberOfBreaches == 0 ? "No breaches detected for" : "Breach detected for")")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle((viewModel.numberOfBreaches == 0 ? PassColor
                                .cardInteractionNormMajor1 : PassColor
                                .passwordInteractionNormMajor2).toColor)
                    Text(email)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(PassColor.textNorm.toColor)
                }

                if !viewModel.isFullyResolved {
                    CapsuleTextButton(title: "Mark as resolved",
                                      titleColor: PassColor.interactionNormMajor2,
                                      backgroundColor: PassColor.interactionNormMinor1,
                                      action: {})
                }
            }
        }
    }
}

private extension DetailMonitoredItemView {
    var breachList: some View {
        LazyVStack {
            if let unresolvedBreaches = viewModel.unresolvedBreaches {
                Section {
                    ForEach(unresolvedBreaches) { breach in
                        breachRow(breach: breach, resolved: false)
                    }
                } header: {
                    Text("Breaches")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                }
            }

            if let resolvedBreaches = viewModel.resolvedBreaches {
                Section {
                    ForEach(resolvedBreaches) { breach in
                        breachRow(breach: breach, resolved: true)
                    }
                } header: {
                    Text("Resolved breaches")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                }
            }
        }
    }
}

// MARK: - Utils

private extension DetailMonitoredItemView {
    func breachRow(breach: Breach, resolved: Bool) -> some View {
        Button(action: {}) {
            HStack(spacing: DesignConstant.sectionPadding) {
                Image(uiImage: resolved ? PassIcon.breachShieldResolved : PassIcon.breachShieldUnresolved)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 43)

                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text(breach.source.domain ?? "<Unknown>")
                        .font(.body)
                        .lineLimit(1)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .minimumScaleFactor(0.5)

                    Text(breach.publishedAt.breachDate)
                        .font(.callout)
                        .lineLimit(1)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .layoutPriority(1)
                        .minimumScaleFactor(0.25)
                }
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toolbar setup

private extension DetailMonitoredItemView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CircleButton(icon: IconProvider.threeDotsVertical,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Breach detail action menu",
                         action: {})
        }
    }
}
