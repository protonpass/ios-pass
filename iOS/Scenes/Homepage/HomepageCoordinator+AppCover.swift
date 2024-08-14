//
// HomepageCoordinator+AppCover.swift
// Proton Pass - Created on 01/08/2024.
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

import DesignSystem
import SwiftUI

extension HomepageCoordinator {
    func coverApp() {
        guard let window else {
            assertionFailure("Root UIWindow not injected")
            return
        }
        if appCoverView == nil {
            let appCoverViewController = makeAppCoverViewController(windowSize: window.frame.size)
            guard let appCoverView = appCoverViewController.view else {
                fatalError("App cover view should not be nil")
            }
            appCoverView.translatesAutoresizingMaskIntoConstraints = false
            appCoverView.alpha = 0
            window.addSubview(appCoverView)
            NSLayoutConstraint.activate([
                appCoverView.topAnchor.constraint(equalTo: window.topAnchor),
                appCoverView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                appCoverView.bottomAnchor.constraint(equalTo: window.bottomAnchor),
                appCoverView.trailingAnchor.constraint(equalTo: window.trailingAnchor)
            ])
            self.appCoverView = appCoverView
            appCoverViewController.didMove(toParent: rootViewController)
        }

        if let appCoverView {
            window.bringSubviewToFront(appCoverView)
            UIView.animate(withDuration: DesignConstant.animationDuration) {
                appCoverView.alpha = 1
            }
        }
    }
}

private extension HomepageCoordinator {
    func makeAppCoverViewController(windowSize: CGSize) -> UIViewController {
        let view = AppCoverView(windowSize: windowSize,
                                onAuth: { [weak self] in
                                    guard let self else { return }
                                    authenticated = false
                                },
                                onAuthSkipped: { [weak self] in
                                    guard let self else { return }
                                    uncoverApp()
                                },
                                onSuccess: { [weak self] in
                                    guard let self else { return }
                                    authenticated = true
                                    uncoverApp()
                                },
                                onFailure: { [weak self] message in
                                    guard let self else { return }
                                    handleFailedLocalAuthentication(message)
                                })
        return UIHostingController(rootView: view)
    }

    func uncoverApp() {
        UIView.animate(withDuration: DesignConstant.animationDuration,
                       animations: { [weak self] in
                           guard let self else { return }
                           appCoverView?.alpha = 0
                       })
    }
}

private struct AppCoverView: View {
    let windowSize: CGSize
    let onAuth: () -> Void
    let onAuthSkipped: () -> Void
    let onSuccess: () -> Void
    let onFailure: (String?) -> Void

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
        .localAuthentication(manuallyAvoidKeyboard: true,
                             onAuth: onAuth,
                             onAuthSkipped: onAuthSkipped,
                             onSuccess: onSuccess,
                             onFailure: onFailure)
    }
}
