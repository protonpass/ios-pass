//
// SelectPasskeyViewModel.swift
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

@preconcurrency import AuthenticationServices
import Entities
import FactoryKit
import Foundation

@MainActor
final class SelectPasskeyViewModel: ObservableObject {
    private weak var context: ASCredentialProviderExtensionContext?
    let info: SelectPasskeySheetInformation

    private let autoFillPasskey = resolve(\AutoFillUseCaseContainer.autoFillPasskey)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let logger = resolve(\SharedToolingContainer.logger)

    init(info: SelectPasskeySheetInformation,
         context: ASCredentialProviderExtensionContext) {
        self.info = info
        self.context = context
    }

    func autoFill(with passkey: Passkey) {
        Task { [weak self] in
            guard let self, let context else { return }
            do {
                logger.debug("Autofilling with selected passkey \(passkey.keyID)")
                try await autoFillPasskey(passkey,
                                          itemContent: info.itemContent,
                                          identifiers: info.identifiers,
                                          params: info.params,
                                          context: context)
                logger.info("Autofilled with selected passkey \(passkey.keyID)")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
