//
// ChildCoordinatorDelegate.swift
// Proton Pass - Created on 14/07/2023.
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

import SwiftUI

/// Control how and what to do before presenting a view
@MainActor
public protocol ChildCoordinatorDelegate: AnyObject {
    func childCoordinatorWantsToPresent(viewController: UIViewController,
                                        viewOption: ChildCoordinatorViewOption,
                                        presentationOption: ChildCoordinatorPresentationOption)
    func childCoordinatorWantsToDismissTopViewController()
    func childCoordinatorDidFailLocalAuthentication()
}

public extension ChildCoordinatorDelegate {
    /// Overloaded method of `childCoordinatorWantsToPresent(viewController:viewOption:presentationOption)`
    /// Conviently pass `some View` instead of `UIViewController`
    @MainActor
    func childCoordinatorWantsToPresent(view: some View,
                                        viewOption: ChildCoordinatorViewOption,
                                        presentationOption: ChildCoordinatorPresentationOption) {
        let viewController = UIHostingController(rootView: view)
        childCoordinatorWantsToPresent(viewController: viewController,
                                       viewOption: viewOption,
                                       presentationOption: presentationOption)
    }
}

public enum ChildCoordinatorViewOption {
    /// Standard sheet
    case sheet
    /// Standard sheet with grabber visible
    case sheetWithGrabber
    /// Sheet with custom height
    case customSheet(CGFloat)
    /// Sheet with custom height and grabber visible
    case customSheetWithGrabber(CGFloat)
    /// Full screen
    case fullScreen
}

public enum ChildCoordinatorPresentationOption {
    /// Do nothing before presenting
    case none
    /// Dismiss top most presented view controller before presenting
    case dismissTopViewController
    /// Dismiss all presented view controllers before presenting
    case dismissAllViewControllers
}
