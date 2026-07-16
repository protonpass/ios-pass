//
// Service+DependencyInjections.swift
// Proton Pass - Created on 25/07/2023.
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
import Core
import DIComposition
import FactoryKit
import ProtonCoreAuthentication
import ProtonCorePushNotifications
import Screens

final class OldServiceContainer: SharedContainer, AutoRegistering {
    static let shared = OldServiceContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

extension OldServiceContainer {
//    @MainActor
//    var paymentManager: Factory<any PaymentsManagerProtocol> {
//        self {
//            /* .init(storage: kSharedUserDefaults) */ PaymentsManager(apiManager: ToolingContainer.shared
//                .apiManager(),
//                userManager: ServiceContainer.shared
//                    .userManager(),
//                authManager: ToolingContainer.shared
//                    .authManager(),
//                mainKeyProvider: ToolingContainer
//                    .shared.mainKeyProvider(),
//                logger: ToolingContainer.shared
//                    .logger())
//        }
//    }
//
//    @MainActor
//    var shareInviteService: Factory<any ShareInviteServiceProtocol> {
//        self { ShareInviteService() }
//    }
//
//    var secureLinkManager: Factory<any SecureLinkManagerProtocol> {
//        self { SecureLinkManager(dataSource: SharedRepositoryContainer.shared.remoteSecureLinkDatasource(),
//                                 userManager: ServiceContainer.shared.userManager()) }
//    }
//
    var onboardingHandler: Factory<any OnboardingHandling> {
        self { OnboardingHandler(logManager: ToolingContainer.shared.logManager(),
                                 userDefaults: kSharedUserDefaults) }
    }
}
