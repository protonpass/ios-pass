//
// EnableAutoFill.swift
// Proton Pass - Created on 11/12/2023.
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

import Client
import UIKit

protocol EnableAutoFillUseCase: Sendable {
    @MainActor
    @discardableResult
    func execute() async -> Bool
}

extension EnableAutoFillUseCase {
    @MainActor
    @discardableResult
    func callAsFunction() async -> Bool {
        await execute()
    }
}

final class EnableAutoFill: EnableAutoFillUseCase {
    private let router: MainUIKitSwiftUIRouter
    private let credentialManager: any CredentialManagerProtocol

    init(router: MainUIKitSwiftUIRouter,
         credentialManager: any CredentialManagerProtocol) {
        self.router = router
        self.credentialManager = credentialManager
    }

    @MainActor
    @discardableResult
    func execute() async -> Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            router.present(for: .autoFillInstructions)
            return true
        } else {
            if #available(iOS 18, *) {
                return await credentialManager.enableAutoFill()
            } else {
                UIApplication.shared.openPasswordSettings()
                return true
            }
        }
    }
}
