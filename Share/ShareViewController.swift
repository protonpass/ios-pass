//
// ShareViewController.swift
// Proton Pass - Created on 22/01/2024.
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

import ProtonCoreCryptoGoImplementation
import Social
import UIKit

final class ShareViewController: UIViewController {
    private lazy var coordinator = ShareCoordinator(rootViewController: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        injectDefaultCryptoImplementation()
        Task { @MainActor [weak self] in
            guard let self else { return }
            await coordinator.start()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .recordLastActiveTimestamp, object: nil)
    }
}
