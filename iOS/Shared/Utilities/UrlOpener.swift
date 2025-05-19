//
// UrlOpener.swift
// Proton Pass - Created on 25/12/2022.
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

import DesignSystem
import FactoryKit
import SafariServices
import UIKit

@MainActor
final class UrlOpener {
    private let getSharedPreferences = resolve(\SharedUseCasesContainer.getSharedPreferences)
    weak var rootViewController: UIViewController?

    init() {}

    func open(urlString: String) {
        assert(rootViewController != nil)

        // Only open URLs with `http` &`https` scheme in browser.
        // Let the system decide for other schemes.
        guard let url = URL(string: urlString) else { return }

        guard let scheme = url.scheme, ["http", "https"].contains(scheme) else {
            fallback(url: url)
            return
        }

        let browser = getSharedPreferences().browser
        switch browser {
        case .inAppSafari:
            let safariViewController = SFSafariViewController(url: url, configuration: .init())
            safariViewController.preferredControlTintColor = PassColor.interactionNorm
            if let rootViewController {
                rootViewController.topMostViewController.present(safariViewController, animated: true)
            } else {
                fallback(url: url)
            }

        default:
            if let appScheme = browser.appScheme {
                let completeUrl = appScheme + (url.host ?? "") + url.path
                if let newUrl = URL(string: completeUrl), UIApplication.shared.canOpenURL(newUrl) {
                    UIApplication.shared.open(newUrl)
                } else {
                    fallback(url: url)
                }
            } else {
                fallback(url: url)
            }
        }
    }

    private func fallback(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
