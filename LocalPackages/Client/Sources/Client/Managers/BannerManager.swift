//
// BannerManager.swift
// Proton Pass - Created on 13/03/2023.
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

import Core
import Entities
import Macro
@preconcurrency import ProtonCoreUIFoundations
import SwiftUI

@MainActor
public protocol BannerDisplayProtocol: Sendable {
    func displayBottomSuccessMessage(_ message: String)

    func displayBottomInfoMessage(_ message: String,
                                  dismissButtonTitle: String,
                                  onDismiss: @escaping @MainActor (PMBanner) -> Void)

    func displayBottomInfoMessage(_ message: String)

    func displayTopErrorMessage(_ message: String,
                                dismissButtonTitle: String,
                                onDismiss: (@MainActor (PMBanner) -> Void)?)

    func displayBottomErrorMessage(_ message: String,
                                   dismissButtonTitle: String,
                                   onDismiss: (@MainActor (PMBanner) -> Void)?)

    func displayTopErrorMessage(_ error: any Error)
}

public extension BannerDisplayProtocol {
    func displayTopErrorMessage(_ message: String,
                                dismissButtonTitle: String? = nil,
                                onDismiss: (@MainActor (PMBanner) -> Void)? = nil) {
        displayTopErrorMessage(message,
                               dismissButtonTitle: dismissButtonTitle ?? #localized("OK", bundle: .module),
                               onDismiss: onDismiss)
    }
}

@MainActor
public final class BannerManager: BannerDisplayProtocol {
    private weak var container: UIViewController?

    public nonisolated init(container: UIViewController?) {
        self.container = container
    }

    public func displayBottomSuccessMessage(_ message: String) {
        display(message: message, at: .passBottom, style: .success)
    }

    public func displayBottomInfoMessage(_ message: String,
                                         dismissButtonTitle: String,
                                         onDismiss: @escaping @MainActor (PMBanner) -> Void) {
        display(message: message,
                at: .passBottom,
                style: .info,
                dismissButtonTitle: dismissButtonTitle,
                onDismiss: onDismiss)
    }

    public func displayBottomInfoMessage(_ message: String) {
        display(message: message, at: .passBottom, style: .info)
    }

    public func displayTopErrorMessage(_ message: String,
                                       dismissButtonTitle: String,
                                       onDismiss: (@MainActor (PMBanner) -> Void)? = nil) {
        display(message: message,
                at: .top,
                style: .error,
                dismissButtonTitle: dismissButtonTitle,
                onDismiss: onDismiss)
    }

    public func displayBottomErrorMessage(_ message: String,
                                          dismissButtonTitle: String,
                                          onDismiss: (@MainActor (PMBanner) -> Void)?) {
        display(message: message,
                at: .bottom,
                style: .error,
                dismissButtonTitle: dismissButtonTitle,
                onDismiss: onDismiss)
    }

    public func displayTopErrorMessage(_ error: any Error) {
        displayTopErrorMessage(customizedMessage(for: error) ?? error.localizedDebugDescription)
    }
}

private extension BannerManager {
    func display(message: String,
                 at position: PMBannerPosition,
                 style: PMBannerNewStyle,
                 dismissButtonTitle: String? = nil,
                 onDismiss: (@MainActor (PMBanner) -> Void)? = nil) {
        guard let host = container?.topMostViewController else { return }

        let displayed = PMBanner.getBanners(in: host)
        guard !displayed.contains(where: { $0.message == message }) else { return }

        let banner = PMBanner(message: message, style: style)
        if let dismissButtonTitle {
            banner.addButton(text: dismissButtonTitle,
                             handler: { banner in
                                 banner.dismiss()
                                 onDismiss?(banner)
                             })
        }
        banner.show(at: position, on: host)
    }

    func customizedMessage(for error: any Error) -> String? {
        if let passError = error as? PassError {
            switch passError {
            case let .vault(reason):
                if case .noEditableVault = reason {
                    // swiftlint:disable:next line_length
                    return #localized("You don't have any vaults with editor or admin access. Try creating one in the main app, or ask your organization's administrator for support.")
                }

            default:
                return nil
            }
        }
        return nil
    }
}

private extension PMBannerPosition {
    /// Custom bottom position for Pass
    static var passBottom: PMBannerPosition {
        .bottomCustom(.init(top: .infinity, left: 8, bottom: 40, right: 8))
    }
}
