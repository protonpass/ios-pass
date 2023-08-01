//
// CancelAutoFill.swift
// Proton Pass - Created on 31/07/2023.
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

import AuthenticationServices
import Core

/// Cancel the autofill process with a given reason
/// e.g: users explicitly cancel, authentication required, authentication failed...
protocol CancelAutoFillUseCase: Sendable {
    func execute(reason: ASExtensionError.Code)
}

extension CancelAutoFillUseCase {
    func callAsFunction(reason: ASExtensionError.Code) {
        execute(reason: reason)
    }
}

final class CancelAutoFill: @unchecked Sendable, CancelAutoFillUseCase {
    private let context: ASCredentialProviderExtensionContext
    private let logManager: LogManagerProtocol

    init(context: ASCredentialProviderExtensionContext,
         logManager: LogManagerProtocol) {
        self.context = context
        self.logManager = logManager
    }

    func execute(reason: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain, code: reason.rawValue)
        context.cancelRequest(withError: error)
        Task {
            await logManager.saveAllLogs()
        }
    }
}
