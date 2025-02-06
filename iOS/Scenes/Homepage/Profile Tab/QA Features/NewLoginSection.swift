//
// NewLoginSection.swift
// Proton Pass - Created on 06/02/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Core
import DesignSystem
import SwiftUI

@available(iOS 17, *)
struct NewLoginSection: View {
    var body: some View {
        NavigationLink(destination: { NewLoginView() },
                       label: { Text(verbatim: "New login flow") })
    }
}

@available(iOS 17, *)
struct NewLoginView: View {
    @State private var viewModel = NewLoginViewModel()

    var body: some View {
        Form {
            Section {
                StaticToggle(.verbatim("Always show new login screen flow"),
                             isOn: viewModel.showNewLogin,
                             action: { viewModel.toggle() })
            } header: {
                Text(verbatim: "Reset feature discovery")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17, *)
@MainActor
@Observable
private final class NewLoginViewModel {
    private(set) var showNewLogin = false
    private let key = Constants.QA.newLoginFlow

    private let storage: UserDefaults

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        refresh()
    }

    private func refresh() {
        showNewLogin = storage.bool(forKey: key)
    }

    func toggle() {
        showNewLogin.toggle()
        storage.set(showNewLogin, forKey: key)
    }
}
