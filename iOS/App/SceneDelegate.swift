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
import DesignSystem
import Factory
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var appCoverView: UIView?
    private lazy var appCoordinator = AppCoordinator(window: window ?? .init())
    private let saveAllLogs = resolve(\SharedUseCasesContainer.saveAllLogs)

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
        coverApp()
        saveAllLogs()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        uncoverApp()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let firstUrl = URLContexts.first?.url else {
            return
        }
       
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

extension String {
    func decodeHTMLAndPercentEntities() -> String {
        let decodedHTML = decodingHTMLEntities()
        return decodedHTML.removingPercentEncoding ?? decodedHTML
    }

    private func decodingHTMLEntities() -> String {
        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        } else {
            return self
        }
    }
}


final class DeepLinkRoutingService {
    private let parseTotpUrl = resolve(\UseCasesContainer.parseTotpUrl)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init() {}
    
    @MainActor func parseAndDispatch(url: URL) {
        switch url.linkType {
        case .otpauth:
            try? parseTotpUrl(uri: url.absoluteString.decodeHTMLAndPercentEntities())
            print("Woot url \(url.absoluteString.decodeHTMLAndPercentEntities())")
            router.deeplink(to: .totp)
        default:
            return
        }
    }
    
}

enum DeeplinkType {
    case otpauth
    case none
}

extension URL {
    var linkType: DeeplinkType {
        if self.scheme == "otpauth" {
            return .otpauth
        }
        return .none
    }
}
