//
// SceneDelegate.swift
// Proton Pass - Created on 01/07/2022.
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

import CoreSpotlight
import DesignSystem
import Factory
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private lazy var appCoordinator = AppCoordinator(window: window ?? .init())
    private let saveAllLogs = resolve(\SharedUseCasesContainer.saveAllLogs)
    @LazyInjected(\RouterContainer.deepLinkRoutingService) var deepLinkRoutingService

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
            window.makeKeyAndVisible()
            RouterContainer.shared.window.register { window }
        }
        AppearanceSettings.apply()
        Task { [weak self] in
            guard let self else { return }
            guard await appCoordinator.setUpAndStart() else {
                return
            }

            deepLinkRoutingService.parseAndDispatch(context: connectionOptions.urlContexts)
            deepLinkRoutingService.handle(userActivities: connectionOptions.userActivities)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        saveAllLogs()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        deepLinkRoutingService.parseAndDispatch(context: URLContexts)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        deepLinkRoutingService.handle(userActivities: [userActivity])
    }
}
