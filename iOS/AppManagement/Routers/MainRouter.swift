//
// MainRouter.swift
// Proton Pass - Created on 19/07/2023.
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

import Combine
import SwiftUI

enum CoordinatorRouterDestination: Hashable {}

enum CoordinatorSheetDestination: Hashable {
    case sharingFlow
}

final class MainUIKitSwiftUIRouter {
    let newPresentationDestination: PassthroughSubject<CoordinatorRouterDestination, Never> = .init()
    let newSheetDestination: PassthroughSubject<CoordinatorSheetDestination, Never> = .init()

    func navigate(to destination: CoordinatorRouterDestination) {
        newPresentationDestination.send(destination)
    }

    func presentSheet(for destination: CoordinatorSheetDestination) {
        newSheetDestination.send(destination)
    }
}

// @available(iOS 16.0, *)
// final class MainNavStackRouter {
//    @Published public var path = NavigationPath()
//    @Published public var presentedSheet: SheetDestination?
//
//    func navigate(to destination: RouterDestination) {
//        path.append(destination)
//    }
//
//    func popToRoot() {
//        path.removeLast(path.count)
//    }
//
//    func back(to numberOfScreen: Int = 1) {
//        path.removeLast(numberOfScreen)
//    }
// }
