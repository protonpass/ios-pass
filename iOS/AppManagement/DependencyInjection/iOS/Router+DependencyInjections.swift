//
// Router+DependencyInjections.swift
// Proton Pass - Created on 19/07/2023.
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

import FactoryKit
import Foundation
import UIKit

final class RouterContainer: SharedContainer, AutoRegistering {
    static let shared = RouterContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

// MARK: Main Router

extension RouterContainer {
    var deepLinkRoutingService: Factory<DeepLinkRoutingService> {
        self { DeepLinkRoutingService(router: SharedRouterContainer.shared.mainUIKitSwiftUIRouter(),
                                      getItemContentFromBase64IDs: UseCasesContainer.shared
                                          .getItemContentFromBase64IDs()) }
    }

    var darkWebRouter: Factory<PathRouter> {
        self { PathRouter() }
            .unique
    }

    var sharingRouter: Factory<PathRouter> {
        self { PathRouter() }
            .unique
    }
}

extension RouterContainer {
    var window: Factory<UIWindow?> {
        self { nil }
    }
}
