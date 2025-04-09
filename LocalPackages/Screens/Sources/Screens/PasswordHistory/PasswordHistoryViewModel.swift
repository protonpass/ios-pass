//
// PasswordHistoryViewModel.swift
// Proton Pass - Created on 09/04/2025.
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
//

import Client
import Entities
import Foundation

@MainActor
final class PasswordHistoryViewModel: ObservableObject {
    @Published private(set) var loading = false
    @Published private(set) var passwords = [GeneratedPasswordUiModel]()
    @Published private(set) var error: (any Error)?

    private var repository: any PasswordHistoryRepositoryProtocol

    init(repository: any PasswordHistoryRepositoryProtocol) {
        self.repository = repository
    }
}

extension PasswordHistoryViewModel {
    func loadPasswords() async {
        defer { loading = false }
        do {
            loading = true
            passwords = try await repository.getAllPasswords()
        } catch {
            self.error = error
        }
    }

    func clearHistory() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.deleteAllPasswords()
                passwords.removeAll()
            } catch {
                self.error = error
            }
        }
    }
}
