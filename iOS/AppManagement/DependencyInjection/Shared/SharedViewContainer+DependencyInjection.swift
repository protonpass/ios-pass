//
// SharedViewContainer+DependencyInjection.swift
// Proton Pass - Created on 15/09/2023.
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
import FactoryKit
import UIKit

final class SharedViewContainer: SharedContainer, AutoRegistering {
    static let shared = SharedViewContainer()

    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .cached
    }

    func register(rootViewController: UIViewController) {
        self.rootViewController.register { rootViewController }
    }

    func reset() {
        SharedViewContainer.shared.bannerManager.reset()
        SharedViewContainer.shared.rootViewController.reset()
    }
}

extension SharedViewContainer {
    var bannerManager: Factory<any BannerDisplayProtocol> {
        self { BannerManager(container: self.rootViewController()) }
    }

    var rootViewController: Factory<UIViewController?> {
        self { nil }
    }
}
