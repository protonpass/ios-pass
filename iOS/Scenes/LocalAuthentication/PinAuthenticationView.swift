//
// PinAuthenticationView.swift
// Proton Pass - Created on 22/06/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Factory
import SwiftUI
import UIComponents

struct PinAuthenticationView: View {
    @ObservedObject private var viewModel: LocalAuthenticationViewModel
    private let preferences = resolve(\SharedToolingContainer.preferences)

    init(viewModel: LocalAuthenticationViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .edgesIgnoringSafeArea(.all)
            Text("PIN authentication")
                .foregroundColor(PassColor.signalDanger.toColor)
        }
        .theme(preferences.theme)
        .onAppear {
            assertionFailure("PIN authentication not yet supported")
        }
    }
}
