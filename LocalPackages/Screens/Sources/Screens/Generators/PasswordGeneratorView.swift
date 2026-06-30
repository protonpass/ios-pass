//
// PasswordGeneratorView.swift
// Proton Pass - Created on 25/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI
import UseCases

public struct PasswordGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PasswordGeneratorViewModel
    private let onHeightChanged: ((Double) -> Void)?

    public init(viewModel: PasswordGeneratorViewModel,
                onHeightChanged: ((Double) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onHeightChanged = onHeightChanged
    }

    public var body: some View {
        mainContent
            .task {
                await viewModel.checkForOrganisationLimitation()
            }
            .onChange(of: viewModel.preferences, initial: true) {
                viewModel.persistAndRegenerate()
            }
    }
}

private extension PasswordGeneratorView {
    var mainContent: some View {
        VStack {
            topBar
        }
        .padding([.top, .horizontal])
        .background(PassColor.backgroundNorm)
        .animation(.default, value: viewModel.password)
        .animation(.default, value: viewModel.showAdvancedOptions)
        .fittedPresentationDetent(onHeightChanged: onHeightChanged)
    }

    @ViewBuilder
    var topBar: some View {
        switch viewModel.mode {
        case .createLogin, .random:
            Text("Generate password", bundle: .module)
                .navigationTitleText()
                .frame(maxWidth: .infinity, alignment: .center)

        case .autofill:
            HStack {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)

                CapsuleTextButton(title: #localized("Use this password", bundle: .module),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.interactionNormMajor1,
                                  action: viewModel.handleCta)
            }
        }
    }
}
