//
// TrashCoordinator.swift
// Proton Pass - Created on 07/07/2022.
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

import Core
import SwiftUI
import UIKit

protocol TrashCoordinatorDelegate: AnyObject {
    func trashCoordinatorWantsToShowSidebar()
}

final class TrashCoordinator: Coordinator {
    weak var delegate: TrashCoordinatorDelegate?

    private lazy var trashViewController: UIViewController = {
        let trashView = TrashView(coordinator: self)
        return UIHostingController(rootView: trashView)
    }()

    override var root: Presentable { trashViewController }

    convenience init() {
        self.init(router: .init(), navigationType: .newFlow(hideBar: false))
    }

    func showSidebar() {
        delegate?.trashCoordinatorWantsToShowSidebar()
    }
}

extension TrashCoordinator {
    /// For preview purposes
    static var preview: TrashCoordinator { .init() }
}
