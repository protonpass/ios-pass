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

import SwiftUI
import UseCases

public struct PasswordGeneratorView: View {
    @State private var viewModel: PasswordGeneratorViewModel

    public init(viewModel: PasswordGeneratorViewModel) {
        self.viewModel = viewModel
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
        Text(verbatim: "Password generator")
    }
}
