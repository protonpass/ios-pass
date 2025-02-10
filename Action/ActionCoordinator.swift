//
// ActionCoordinator.swift
// Proton Pass - Created on 09/02/2025.
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

import Factory
import UIKit

@MainActor
final class ActionCoordinator {
    @LazyInjected(\SharedUseCasesContainer.setUpBeforeLaunching) private var setUpBeforeLaunching

    private weak var rootViewController: UIViewController?
    private var context: NSExtensionContext? { rootViewController?.extensionContext }

    init(rootViewController: UIViewController?) {
        self.rootViewController = rootViewController
    }
}

// MARK: Public APIs

extension ActionCoordinator {
    func start() async {
        do {
            try await setUpBeforeLaunching(rootContainer: .viewController(rootViewController))
        } catch {
//            alert(error: error) { [weak self] in
//                guard let self else { return }
//                dismissExtension()
//            }
        }
    }
}

// MARK: Private APIs

private extension ActionCoordinator {}
