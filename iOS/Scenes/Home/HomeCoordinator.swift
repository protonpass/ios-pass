//
// HomeCoordinator.swift
// Proton Key - Created on 02/07/2022.
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

final class HomeCoordinator: Coordinator {
    private let appStateObserver: AppStateObserver

    private lazy var homeViewController: UIViewController = {
        let homeView = HomeView(coordinator: self)
        return UIHostingController(rootView: homeView)
    }()

    init(router: Router,
         navigationType: Coordinator.NavigationType,
         appStateObserver: AppStateObserver) {
        self.appStateObserver = appStateObserver
        super.init(router: router, navigationType: navigationType)
    }

    override var root: Presentable { homeViewController }

    func logOut() {
        appStateObserver.updateState(.loggedOut)
    }
}

extension HomeCoordinator {
    /// For previews purposes
    static var preview: HomeCoordinator {
        .init(router: .init(),
              navigationType: .currentFlow,
              appStateObserver: .init())
    }
}

struct HomeView: View {
    let coordinator: HomeCoordinator

    var body: some View {
        VStack {
            Text("Welcome to Proton Key")
            Button("Log out", action: coordinator.logOut)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(coordinator: .preview)
    }
}
