//
// PasskeyCredentialsViewModel.swift
// Proton Pass - Created on 27/02/2024.
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

import Client
import Entities
import Factory
import Foundation

enum PasskeyCredentialsViewModelState {
    case loading
    case loaded([SearchableItem], [ItemUiModel])
    case error(Error)
}

@MainActor
final class PasskeyCredentialsViewModel: ObservableObject {
    @Published private(set) var state: PasskeyCredentialsViewModelState = .loading

    @LazyInjected(\AutoFillUseCaseContainer.getItemsForPasskeyCreation) private var getItemsForPasskeyCreation

    init() {}
}

extension PasskeyCredentialsViewModel {
    func loadCredentials() async {
        do {
            if case .error = state {
                state = .loading
            }
            let result = try await getItemsForPasskeyCreation()
            state = .loaded(result.0, result.1)
        } catch {
            state = .error(error)
        }
    }
}
