//
// FullSyncPresenting.swift
// Proton Pass - Created on 21/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Screens
import UseCases

@MainActor
protocol FullSyncPresenting {
    var router: any UIKitSwiftUIBridgeRouterProtocol { get }
    var fullContentSync: any FullContentSyncUseCase { get }
    var logger: Logger { get }
}

extension FullSyncPresenting {
    /// Shows the non-dismissible full sync screen, runs the sync and announces the outcome.
    ///
    /// The success message is conditional because `fullContentSync` reports failures on
    /// `vaultSyncEventStream` instead of throwing: announcing unconditionally stacks a
    /// "refreshed" toast on top of the retry screen the user is looking at.
    func presentFullSync(userId: String, shouldStopEventLoop: Bool, reason: String) async {
        router.present(for: .fullSync)
        logger.info("Full syncing: \(reason)")
        let succeeded = await fullContentSync(userId: userId,
                                              shouldStopEventLoop: shouldStopEventLoop)
        logger.info("Done full syncing: \(reason), succeeded: \(succeeded)")
        guard succeeded else { return }
        router.display(element: .successMessage(config: .refresh))
    }
}
