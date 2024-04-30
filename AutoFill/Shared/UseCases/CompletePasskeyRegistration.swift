//
// CompletePasskeyRegistration.swift
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

import AuthenticationServices
import Entities
import Foundation
import UseCases

protocol CompletePasskeyRegistrationUseCase: Sendable {
    func execute(_ response: CreatePasskeyResponse,
                 context: ASCredentialProviderExtensionContext)
}

extension CompletePasskeyRegistrationUseCase {
    func callAsFunction(_ response: CreatePasskeyResponse,
                        context: ASCredentialProviderExtensionContext) {
        execute(response, context: context)
    }
}

final class CompletePasskeyRegistration: CompletePasskeyRegistrationUseCase {
    private let addTelemetryEvent: any AddTelemetryEventUseCase
    private let resetFactory: any ResetFactoryUseCase

    init(addTelemetryEvent: any AddTelemetryEventUseCase,
         resetFactory: any ResetFactoryUseCase) {
        self.addTelemetryEvent = addTelemetryEvent
        self.resetFactory = resetFactory
    }

    func execute(_ response: CreatePasskeyResponse,
                 context: ASCredentialProviderExtensionContext) {
        guard #available(iOS 17, *) else {
            assertionFailure("Should be called on iOS 17 and above")
            return
        }
        // Add telemetry event before completing on purpose
        // because after completing the extension is dismissed
        addTelemetryEvent(with: .passkeyCreate)
        let credential = ASPasskeyRegistrationCredential(relyingParty: response.rpId ?? response.rpName,
                                                         clientDataHash: response.clientDataHash,
                                                         credentialID: response.credentialId,
                                                         attestationObject: response.attestationObject)
        context.completeRegistrationRequest(using: credential)
        resetFactory()
    }
}
