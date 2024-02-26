//
// LockedCredentialViewModel.swift
// Proton Pass - Created on 25/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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

@preconcurrency import AuthenticationServices
import Entities
import Factory

@MainActor
final class LockedCredentialViewModel: ObservableObject {
    private let request: AutoFillRequest
    private let logger = resolve(\SharedToolingContainer.logger)

    @LazyInjected(\AutoFillUseCaseContainer.generateAuthorizationCredential)
    private var generateAuthorizationCredential

    var onFailure: ((Error) -> Void)?
    var onSuccess: ((any ASAuthorizationCredential, ItemContent) -> Void)?

    init(request: AutoFillRequest) {
        self.request = request
    }

    func getAndReturnCredential() {
        logger.info("Local authentication succesful")
        Task { [weak self] in
            guard let self else { return }
            do {
                let (itemContent, credential) = try await generateAuthorizationCredential(request)
                onSuccess?(credential, itemContent)
            } catch {
                logger.error(error)
                onFailure?(error)
            }
        }
    }

    func handleAuthenticationFailure() {
        logger.info("Failed to locally authenticate. Logging out.")
        onFailure?(PassError.credentialProvider(.failedToAuthenticate))
    }

    func handleCancellation() {
        onFailure?(PassError.credentialProvider(.userCancelled))
    }
}
