//
//
// SecurityCenterViewModel.swift
// Proton Pass - Created on 29/02/2024.
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

import Entities
import Factory
import Foundation

extension Dictionary where Value: Collection {
    var totalElementsCount: Int {
        values.reduce(0) { $0 + $1.count }
    }
}

@MainActor
final class SecurityCenterViewModel: ObservableObject, Sendable {
    @Published private(set) var weakPasswordsLogins: [PasswordStrength: [ItemContent]]?
    @Published private(set) var reusedPasswordsLogins: [Int: [ItemContent]]?
    @Published private(set) var breachedPasswords: [Int: [ItemContent]]?
    @Published private(set) var breachedEmails: [Int: [ItemContent]]?
    @Published private(set) var missing2FA: [ItemContent] = []
    @Published private(set) var excludedItemsForMonitoring: [ItemContent] = []

    @Published private(set) var loading = false

    private let getWeakPasswordLogins = resolve(\UseCasesContainer.getAllWeakPasswordLogins)

    init() {
        setUp()
    }

    func loadContent() async {
        loading = true
        defer { loading = false }
        do {
            async let weakPasswords = getWeakPasswordLogins()
            let results = try await [weakPasswords]
            weakPasswordsLogins = results.first
        } catch {}
    }
}

private extension SecurityCenterViewModel {
    func setUp() {
        Task { [weak self] in
            guard let self else {
                return
            }
            await loadContent()
        }
    }
}
