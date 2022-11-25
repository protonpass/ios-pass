//
// BannerManager.swift
// Proton Pass - Created on 17/11/2022.
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

import ProtonCore_UIFoundations

public final class BannerManager {
    let container: UIViewController

    public init(container: UIViewController) {
        self.container = container
    }

    public func display(message: String, at position: PMBannerPosition, style: PMBannerNewStyle) {
        let banner = PMBanner(message: message, style: style)
        let viewController: UIViewController
        if let presentedViewController = container.presentedViewController,
           !presentedViewController.isBeingDismissed {
            viewController = presentedViewController
        } else {
            viewController = container
        }
        banner.show(at: position, on: viewController)
    }

    public func displayBottomSuccessMessage(_ message: String) {
        display(message: message, at: .bottom, style: .success)
    }

    public func displayBottomInfoMessage(_ message: String) {
        display(message: message, at: .bottom, style: .info)
    }

    public func displayTopErrorMessage(_ message: String,
                                       dismissButtonTitle: String = "OK",
                                       onDismiss: ((PMBanner) -> Void)? = nil) {
        let dismissClosure = onDismiss ?? { banner in banner.dismiss() }
        let banner = PMBanner(message: message, style: PMBannerNewStyle.error)
        banner.addButton(text: dismissButtonTitle, handler: dismissClosure)
        banner.show(at: .top, on: container)
    }
}
