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
    /// Runs the sync and refreshes the UI when it succeeds. The progress sheet is presented by
    /// `HomepageCoordinator` whenever a sync of the active user starts, so callers never present it.
    ///
    /// The refresh is conditional because `fullContentSync` reports failures in its return value
    /// instead of throwing.
    func runFullSync(userId: String, shouldStopEventLoop: Bool, reason: String) async {
        logger.info("Full syncing: \(reason)")
        let succeeded = await fullContentSync.execute(userId: userId,
                                                      shouldStopEventLoop: shouldStopEventLoop)
        logger.info("Done full syncing: \(reason), succeeded: \(succeeded)")
        guard succeeded else { return }
        router.display(element: .successMessage(config: .refresh))
    }
}
