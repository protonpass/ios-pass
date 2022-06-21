//
// LogInCoordinator.swift
// Proton Key - Created on 21/06/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Key.
//
// Proton Key is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Key is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Key. If not, see https://www.gnu.org/licenses/.

import Core
import SwiftUI
import UIKit

final class LogInCoordinator: Coordinator {
    private let appStateObserver: AppStateObserver

    private lazy var logInController: UIViewController = {
        let logInView = LogInView(coordinator: self)
        return UIHostingController(rootView: logInView)
    }()

    init(router: Router,
         navigationType: Coordinator.NavigationType,
         appStateObserver: AppStateObserver) {
        self.appStateObserver = appStateObserver
        super.init(router: router, navigationType: navigationType)
    }

    override var root: Presentable { logInController }

    func showHome() {
        appStateObserver.updateState(.loggedIn)
    }
}

struct LogInView: View {
    let coordinator: LogInCoordinator

    var body: some View {
        VStack {
            Text("Proton Key")
            Button("Log in") {
                coordinator.showHome()
            }
        }
    }
}
