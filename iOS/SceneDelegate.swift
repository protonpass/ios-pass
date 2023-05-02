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
import SwiftUI
import UIComponents

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var appCoverView: UIView?
    private lazy var appCoordinator = AppCoordinator(window: window ?? .init())

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
    }

    func sceneWillResignActive(_ scene: UIScene) {
        let appCoverView = makeAppCoverView()
        appCoverView.frame = window?.frame ?? .zero
        window?.addSubview(appCoverView)
        self.appCoverView = appCoverView
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appCoverView?.removeFromSuperview()
        appCoverView = nil
    }
}

private extension SceneDelegate {
    struct AppCoverView: View {
        var body: some View {
            ZStack {
                Color(uiColor: PassColor.backgroundNorm)
                    .ignoresSafeArea()
                Image(uiImage: PassIcon.passIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 160)
            }
            .theme(Preferences().theme)
        }
    }

    func makeAppCoverView() -> UIView {
        UIHostingController(rootView: AppCoverView()).view
    }
}
