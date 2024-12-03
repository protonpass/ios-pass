//
// UIViewController+Extensions.swift
// Proton Pass - Created on 16/06/2023.
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

import UIKit

public enum SheetDetentType {
    case medium
    case large
    case mediumAndLarge
    case custom(CGFloat)
    case customAndLarge(CGFloat)
}

public extension UIViewController {
    func setDetentType(_ type: SheetDetentType, parentViewController: UIViewController) {
        let parentWindow = parentViewController.view.window
        let screenHeight = parentWindow?.bounds.height ?? UIScreen.main.bounds.height

        let detents: [UISheetPresentationController.Detent] = makeDetents(for: type, screenHeight: screenHeight)

        sheetPresentationController?.detents = detents
    }

    /// Top most presented view controller
    var topMostViewController: UIViewController {
        var topMostViewController = self
        while true {
            if let presentationController = topMostViewController.presentedViewController {
                if presentationController.isBeingDismissed {
                    break
                }
                topMostViewController = presentationController
            } else {
                break
            }
        }
        return topMostViewController
    }

    func containsUniqueSheet(_ tag: any RawRepresentable<Int>) -> Bool {
        var topMostViewController = self
        while true {
            if let presentedViewController = topMostViewController.presentedViewController {
                if presentedViewController.view.tag == tag.rawValue {
                    return true
                }
                topMostViewController = presentedViewController
            } else {
                break
            }
        }
        return false
    }

    func viewControllerWithTag(_ tag: any RawRepresentable<Int>) -> UIViewController? {
        var topMostViewController = self
        while true {
            if let presentedViewController = topMostViewController.presentedViewController {
                if presentedViewController.view.tag == tag.rawValue {
                    return presentedViewController
                }
                topMostViewController = presentedViewController
            } else {
                break
            }
        }
        return nil
    }
}

private extension UIViewController {
    func makeDetents(for type: SheetDetentType,
                     screenHeight: CGFloat) -> [UISheetPresentationController.Detent] {
        let customDetent: (CGFloat) -> UISheetPresentationController.Detent = { height in
            UISheetPresentationController.Detent.custom { _ in height }
        }

        switch type {
        case .medium:
            return [.medium()]
        case .large:
            return [.large()]
        case .mediumAndLarge:
            return [.medium(), .large()]
        case let .custom(height):
            if height > screenHeight {
                return [.large()]
            } else {
                return [customDetent(height)]
            }
        case let .customAndLarge(height):
            if height >= screenHeight * 0.8 {
                return [.large()]
            } else {
                return [customDetent(height), .large()]
            }
        }
    }
}
