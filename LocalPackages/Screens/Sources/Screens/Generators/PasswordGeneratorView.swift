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
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI
import UseCases

public struct PasswordGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PasswordGeneratorViewModel
    @State private var maxPasswordHeight = 0.0
    private let onHeightChanged: ((Double) -> Void)?

    public init(viewModel: PasswordGeneratorViewModel,
                onHeightChanged: ((Double) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onHeightChanged = onHeightChanged
    }

    public var body: some View {
        VStack {
            mainContent
        }
        .frame(maxHeight: viewModel.mode.fullScreen ? .infinity : nil)
        .task {
            await viewModel.checkForOrganisationLimitation()
        }
        .onChange(of: viewModel.preferences, initial: true) {
            viewModel.persistAndRegenerate()
        }
        .padding([.top, .horizontal])
        .background(PassColor.backgroundNorm)
        .animation(.default, value: viewModel.password)
        .animation(.default, value: viewModel.showAdvancedOptions)
        .if(!viewModel.mode.fullScreen) { view in
            view
                .fittedPresentationDetent(onHeightChanged: onHeightChanged)
        }
    }
}

private extension PasswordGeneratorView {
    @ViewBuilder
    var mainContent: some View {
        topBar

        // The height of password text grows as text gets longer
        // We remember the last known max height and make it the min height
        // in order to avoid animation glitch when height increases and decreases as lenght changes
        Text(viewModel.password.coloredPassword())
            .font(.title3.monospaced())
            .frame(minHeight: max(32, maxPasswordHeight), alignment: .center)
            .fixedSize(horizontal: false, vertical: true)
            .animationsDisabled()
            .onGeometryChange(for: Double.self,
                              of: { $0.size.height },
                              action: { newHeight in
                                  if newHeight > maxPasswordHeight {
                                      maxPasswordHeight = newHeight
                                  }
                              })

        if viewModel.mode.fullScreen {
            Spacer()
        }
    }

    @ViewBuilder
    var topBar: some View {
        switch viewModel.mode {
        case .createLogin, .random:
            HStack {
                circleRegenerateButton
                    .opacity(0)
                Text("Generate password", bundle: .module)
                    .navigationTitleText()
                    .frame(maxWidth: .infinity, alignment: .center)
                circleRegenerateButton
            }

        case .autofill:
            HStack {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)

                Spacer()

                CapsuleTextButton(title: #localized("Use this password", bundle: .module),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.interactionNormMajor1,
                                  maxWidth: nil,
                                  action: viewModel.handleCta)
            }
        }
    }

    var circleRegenerateButton: some View {
        CircleButton(icon: IconProvider.arrowsRotate,
                     iconColor: PassColor.loginInteractionNormMajor2,
                     backgroundColor: PassColor.loginInteractionNormMinor1,
                     accessibilityLabel: "Regenerate password",
                     action: { viewModel.regenerate() })
    }
}

private extension PasswordGeneratorMode {
    var fullScreen: Bool {
        if case .autofill = self {
            true
        } else {
            false
        }
    }
}
