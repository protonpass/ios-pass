//
//
// BreachDetailView.swift
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
import ProtonCoreUIFoundations
import SwiftUI

struct BreachDetailView: View {
    private let breach: Breach
    @Environment(\.dismiss) private var dismiss
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init(breach: Breach) {
        self.breach = breach
    }

    var body: some View {
        NavigationStack {
            mainContainer
        }
    }
}

private extension BreachDetailView {
    @MainActor
    var mainContainer: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            headerInfo
            exposedInfos
            detailsInfos
            if !breach.actions.isEmpty {
                recommendedActions
            }
            footer
                .onTapGesture {
                    router.navigate(to: .urlPage(urlString: "https://proton.me/blog/breach-recommendations"))
                }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PassColor.backgroundNorm.toColor,
                           for: .navigationBar)
    }
}

private extension BreachDetailView {
    var headerInfo: some View {
        HStack(spacing: 12) {
            Image(uiImage: breach.isResolved ? PassIcon.breachShieldResolved : PassIcon
                .breachShieldUnresolved)
                .resizable()
                .scaledToFit()
                .frame(height: 50)
            VStack {
                Text(breach.name)
                    .font(.title3)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Your info was in a data breach and found on **\(breach.breachDate)**")
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private extension BreachDetailView {
    var exposedInfos: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(breach.exposedData, id: \.self) { item in
                        Text(item.name)
                            .font(.caption)
                            .foregroundStyle(PassColor.textInvert.toColor)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 15)
                            .background(PassColor.signalDanger.toColor)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
            }
        } header: {
            createSectionHeader(title: "Your exposed information")
        }
    }
}

private extension BreachDetailView {
    var detailsInfos: some View {
        Section {
            VStack(spacing: 12) {
                VStack {
                    Text("Email address")
                        .fontWeight(.thin)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(breach.email)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let passwordLastChars = breach.passwordLastChars {
                    VStack {
                        Text("Password")
                            .fontWeight(.thin)
                            .foregroundStyle(PassColor.textNorm.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(passwordLastChars)
                            .foregroundStyle(PassColor.textNorm.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } header: {
            createSectionHeader(title: "Details")
        }
    }
}

private extension BreachDetailView {
    var recommendedActions: some View {
        Section {
            VStack(spacing: 12) {
                ForEach(breach.actions, id: \.self) { item in
                    HStack {
                        VStack {
                            Spacer()
                            Image(uiImage: item.knownCode.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                                .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                            Spacer()
                        }
                        Text(item.name)
                            .foregroundStyle(PassColor.textNorm.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(DesignConstant.sectionPadding)
                    .background(PassColor.inputBackgroundNorm.toColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        } header: {
            createSectionHeader(title: "Recommended actions")
        }
    }
}

private extension BreachDetailView {
    var footer: some View {
        Text("Your Proton Account information remains secure and encrypted.")
            .font(.callout)
            .adaptiveForegroundStyle(PassColor.textWeak.toColor) +
            Text(verbatim: " ") +
            Text("Learn more")
            .adaptiveForegroundStyle(PassColor.interactionNormMajor2.toColor)
            .underline()
    }
}

// MARK: - utils

private extension BreachDetailView {
    func createSectionHeader(title: LocalizedStringKey) -> some View {
        Text(title)
            .monitorSectionTitleText()
            .padding(.top, DesignConstant.sectionPadding)
    }
}

private extension BreachDetailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }
    }
}

private extension BreachActionCode {
    var icon: UIImage {
        switch self {
        case .stayAlert:
            IconProvider.checkmark
        case .passwordAll, .passwordExposed, .passwordSource:
            IconProvider.key
        case .twoFA:
            IconProvider.locks
        case .aliases:
            IconProvider.alias
        case .unknown:
            IconProvider.infoCircle
        }
    }
}
