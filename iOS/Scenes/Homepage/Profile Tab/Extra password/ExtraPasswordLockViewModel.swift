//
// ExtraPasswordLockViewModel.swift
// Proton Pass - Created on 06/06/2024.
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
import Core
import Entities
import Factory
import Foundation

@preconcurrency import ProtonCoreServices

@MainActor
final class ExtraPasswordLockViewModel: ObservableObject {
    @Published private(set) var loading = false
    @Published private(set) var result: ExtraPasswordVerificationResult?
    @Published private(set) var error: (any Error)?
    @Published var extraPassword = ""

    var canProceed: Bool { extraPassword.count >= Constants.ExtraPassword.minLength }

    private let verifyExtraPassword = resolve(\UseCasesContainer.verifyExtraPassword)
    private let extraPasswordRepository: any ExtraPasswordRepositoryProtocol
    private let userId: String

    init(apiServicing: any APIManagerProtocol, userId: String) {
        self.userId = userId
        extraPasswordRepository = ExtraPasswordRepository(apiServicing: apiServicing)
    }
}

extension ExtraPasswordLockViewModel {
    func unlock(_ username: String) {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                result = nil
                loading = true
                result = try await verifyExtraPassword(repository: extraPasswordRepository,
                                                       userId: userId,
                                                       username: username,
                                                       password: extraPassword)
            } catch {
                self.error = error
            }
        }
    }
}
