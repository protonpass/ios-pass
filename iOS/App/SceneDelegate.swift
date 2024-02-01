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

import Core
import CoreSpotlight
import DesignSystem
import Entities
import Factory
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var appCoverView: UIView?
    private lazy var appCoordinator = AppCoordinator(window: window ?? .init())
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let saveAllLogs = resolve(\SharedUseCasesContainer.saveAllLogs)
    private let deepLinkRoutingService = resolve(\RouterContainer.deepLinkRoutingService)
    private let getItemContentFromBase64IDs = resolve(\UseCasesContainer.getItemContentFromBase64IDs)
    private let pendingSpotlightItem = resolve(\DataStreamContainer.pendingSpotlightItem)

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
            window.makeKeyAndVisible()
        }
        AppearanceSettings.apply()
        appCoordinator.start()

        deepLinkRoutingService.parseAndDispatch(context: connectionOptions.urlContexts)
        handle(userActivities: connectionOptions.userActivities)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        coverApp()
        saveAllLogs()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        uncoverApp()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        deepLinkRoutingService.parseAndDispatch(context: URLContexts)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handle(userActivities: [userActivity])
    }
}

// MARK: - App cover

private extension SceneDelegate {
    struct AppCoverView: View {
        private let preferences = resolve(\SharedToolingContainer.preferences)
        let windowSize: CGSize

        var body: some View {
            ZStack {
                Image(uiImage: PassIcon.coverScreenBackground)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                Image(uiImage: PassIcon.coverScreenLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(windowSize.width, windowSize.height) * 2 / 3)
                    .frame(maxWidth: 245)
            }
            .theme(preferences.theme)
        }
    }

    func makeAppCoverView(windowSize: CGSize) -> UIView {
        UIHostingController(rootView: AppCoverView(windowSize: windowSize)).view
    }

    func coverApp() {
        let appCoverView = makeAppCoverView(windowSize: window?.frame.size ?? .zero)
        appCoverView.frame = window?.frame ?? .zero
        appCoverView.alpha = 0
        window?.addSubview(appCoverView)
        UIView.animate(withDuration: 0.35) {
            appCoverView.alpha = 1
        }
        self.appCoverView = appCoverView
    }

    func uncoverApp() {
        UIView.animate(withDuration: 0.35,
                       animations: { [weak self] in
                           guard let self else { return }
                           appCoverView?.alpha = 0
                       },
                       completion: { [weak self] _ in
                           guard let self else { return }
                           appCoverView?.removeFromSuperview()
                           appCoverView = nil
                       })
    }
}

private extension SceneDelegate {
    func handle(userActivities: Set<NSUserActivity>) {
        for activity in userActivities {
            switch activity.activityType {
            case CSSearchableItemActionType:
                if let base64Ids = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                    showItemDetail(base64Ids: base64Ids)
                }
            default:
                break
            }
        }
    }

    func showItemDetail(base64Ids: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let itemContent = try await getItemContentFromBase64IDs(for: base64Ids)
                pendingSpotlightItem.send(itemContent)
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
